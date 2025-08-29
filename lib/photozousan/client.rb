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
      File.open(File.join(album_dir, 'album_info.json'), 'w') do |file|
        file.write(album_info.to_json)
      end
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

      original_image_url = extInfo['info']['photo']['original_image_url']
      original_image_uri = URI.parse(original_image_url)
    end

    def download(result)
      print 'start download.....'
      result["info"]["photo"].each do |photo|
        img_uri = URI.parse(photo["original_image_url"])
        id = photo["photo_id"]
        original_image_uri = get_original_image_uri(id)

        File.binwrite(
          File.join(@base_dir, "#{id}.jpg"),
          URI.open(original_image_uri, http_basic_authentication: @certs).read
        )
        print '.'
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
