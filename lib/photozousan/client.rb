require 'open-uri'
require 'openssl'
require 'json'
require 'fileutils'

module Photozousan
  class Client
    PHOTO_INFO_URL = "https://api.photozou.jp/rest/photo_info.json?private=true&photo_id="
    PHOTO_ALBUM_URL = "https://api.photozou.jp/rest/photo_album.json"
    PHOTO_ALBUM_PHOTO_URL = "https://api.photozou.jp/rest/photo_album_photo.json"

    def initialize(id, pass, album_id = nil)
      @certs = [id, pass]
      @album_id = album_id
      create_album_dir(album_id) if album_id
    end

    def create_album_dir(album_id)
      timestamp = Time.now.strftime('%Y%m%d%H%M%S')
      @base_dir = if album_id
                    "Original_#{album_id}_#{timestamp}"
                  else
                    "Original_#{timestamp}"
                  end
      FileUtils.mkdir_p(@base_dir)

      info = get_album_info(album_id)
      write_album_info(info, @base_dir)
    end


    def dowmload_all_images(album_id, limit)
      # フォルダがまだ作成されていない場合は作成
      create_album_dir(album_id) unless @base_dir
      download(get_all_photos(album_id, limit))
    end

    private

    def write_album_info(album_info, album_dir)
      # JSONファイルを出力
      File.open(File.join(album_dir, 'album_info.json'), 'w') do |file|
        file.write(album_info.to_json)
      end

      # Markdownファイルを出力
      File.open(File.join(album_dir, 'album_info.md'), 'w') do |file|
        file.write(generate_markdown(album_info))
      end
    end

    def generate_markdown(album_info)
      return "# アルバム情報が見つかりません\n\nアルバム情報の取得に失敗しました。" unless album_info

      markdown = []
      markdown << "# #{album_info['name'] || 'アルバム名なし'}"
      markdown << ""

      if album_info['description'] && !album_info['description'].empty?
        markdown << "## 説明"
        markdown << ""
        markdown << album_info['description'].gsub("\r\n", "\n")
        markdown << ""
      end

      markdown << "## 基本情報"
      markdown << ""
      markdown << "| 項目 | 値 |"
      markdown << "|------|-----|"
      markdown << "| アルバムID | #{album_info['album_id']} |"
      markdown << "| ユーザーID | #{album_info['user_id']} |"
      markdown << "| 写真数 | #{album_info['photo_num']}枚 |"
      markdown << "| 作成日時 | #{album_info['created_time']} |"
      markdown << "| 更新日時 | #{album_info['updated_time']} |"
      markdown << "| 権限タイプ | #{album_info['perm_type']} |"
      markdown << "| 公開範囲 | #{album_info['perm_type2']} |"
      markdown << "| 並び順 | #{album_info['order_type']} |"
      markdown << "| 著作権 | #{album_info['copyright_type']} |"
      markdown << "| 商用利用 | #{album_info['copyright_commercial']} |"
      markdown << "| 改変許可 | #{album_info['copyright_modifications']} |"
      markdown << ""

      if album_info['cover_photo_id']
        markdown << "## カバー写真"
        markdown << ""
        markdown << "カバー写真ID: #{album_info['cover_photo_id']}"
        markdown << ""
      end

      if album_info['perm_msg'] && !album_info['perm_msg'].empty?
        markdown << "## 公開メッセージ"
        markdown << ""
        markdown << album_info['perm_msg']
        markdown << ""
      end

      if album_info['upload_email'] && !album_info['upload_email'].empty?
        markdown << "## アップロード情報"
        markdown << ""
        markdown << "アップロード用メールアドレス: #{album_info['upload_email']}"
        markdown << ""
      end

      markdown.join("\n")
    end

    def get_album_info(album_id)
      album_info_uri = URI.parse(PHOTO_ALBUM_URL)

      response = JSON.parse(URI.open(album_info_uri,
        http_basic_authentication: @certs,
        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
      ).read)

      # APIレスポンスの構造に応じて処理
      if response.is_a?(Hash) && response['stat'] == 'ok'
        # 成功レスポンスの場合
        if response['info'] && response['info']['album']
          # 指定されたalbum_idのアルバム情報を検索
          album_info = response['info']['album'].find { |album| album['album_id'] == album_id.to_i }
          if album_info
            puts "Found album: #{album_info['name']} - #{album_info['description']}"
            return album_info
          else
            puts "Album #{album_id} not found in the list"
            return { 'album_id' => album_id, 'status' => 'not_found' }
          end
        else
          puts "No album information in response"
          return { 'album_id' => album_id, 'status' => 'no_album_info' }
        end
      else
        puts "API call failed: #{response}"
        return nil
      end
    end

    def get_original_image_uri(photo_id)
      extInfo_uri = URI.parse(PHOTO_INFO_URL + photo_id.to_s)

      # 認証情報付きでAPIを呼び出し（非公開アルバムのダウンロード対応）
      extInfo = JSON.parse(URI.open(extInfo_uri,
        http_basic_authentication: @certs,
        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
      ).read)

      if extInfo['info'] && extInfo['info']['photo'] && extInfo['info']['photo']['original_image_url']
        original_image_url = extInfo['info']['photo']['original_image_url']
        URI.parse(original_image_url)
      else
        raise "Photo info not found for photo_id: #{photo_id}. Response: #{extInfo}"
      end
    end

    def download(result)
      print 'start download.....'
      result["info"]["photo"].each do |photo|
        id = photo["photo_id"]
        begin
          original_image_uri = get_original_image_uri(id)

          File.binwrite(
            File.join(@base_dir, "#{id}.jpg"),
            URI.open(original_image_uri, http_basic_authentication: @certs).read
          )
          print '.'
        rescue => e
          puts "\nError downloading photo #{id}: #{e.message}"
          puts "Photo ID: #{id}"
          puts "URL: #{original_image_uri}" if defined?(original_image_uri)
          # エラーが発生しても他の写真のダウンロードを続行
          next
        end
      end
      puts 'finished.'
    end

    def get_all_photos(album_id, limit)
      print "\n...getting all image-urls...."
      uri = URI.parse(PHOTO_ALBUM_PHOTO_URL)
      query = URI.encode_www_form(album_id: album_id, limit: limit)
      full_uri = URI.parse("#{uri}?#{query}")

      result = URI.open(full_uri,
        http_basic_authentication: @certs,
        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
      ).read
      puts 'success!'
      JSON.parse(result)
    end
  end
end
