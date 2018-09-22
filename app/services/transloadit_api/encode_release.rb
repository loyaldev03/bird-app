module TransloaditApi
  class EncodeRelease
    require 'transloadit'
    attr_reader :tracks, :transloadit_client, :release, :steps

    def initialize(release)
      @transloadit_client = TRANSLOADIT
      @release = release
      @tracks = release.tracks
      @steps = []
    end

    def call
      return if release.assembly_complete? || !release.tracks.exists? || release.catalog.blank?
      tracks.each do |t|
        steps << transloadit_client.step("import_track_#{t.id}", '/http/import', {
          url: t.uri.url
        })
        steps << transloadit_client.step("ogg_#{t.id}", '/audio/encode', {
          use: "import_track_#{t.id}",
          preset: 'ogg',
          bitrate: 64000,
          ffmpeg_stack: 'v3.3.3',
          result: true
        })

        steps << transloadit_client.step("mp3_#{t.id}", '/audio/encode', {
          use: "import_track_#{t.id}",
          preset: 'mp3',
          ffmpeg_stack: 'v3.3.3',
          result: true
        })

        steps << transloadit_client.step("wav_#{t.id}", '/audio/encode', {
          use: "import_track_#{t.id}",
          preset: 'wav',
          ffmpeg_stack: 'v3.3.3',
          result: true
        })

        steps << transloadit_client.step("flac_#{t.id}", '/audio/encode', {
          use: "import_track_#{t.id}",
          preset: 'flac',
          ffmpeg_stack: 'v3.3.3',
          result: true
        })

        steps << transloadit_client.step("aiff_#{t.id}", '/audio/encode', {
          use: "import_track_#{t.id}",
          ffmpeg: {
                    "write_id3v1": 1,
                    "write_id3v2": 1,
                    "id3v2_version": 3,
                    "f": "aiff"
                  },
          ffmpeg_stack: 'v3.3.3',
          result: true
        })

        ['aiff', 'flac', 'mp3', 'wav'].each do |format|
          steps << transloadit_client.step("zip_#{format}_#{t.id}", '/file/compress', {
            format: 'zip',
            file_layout: 'simple',
            use: "#{format}_#{t.id}"
          })
          steps << transloadit_client.step("store_zip_#{format}_#{t.id}", '/s3/store', {
            key: ENV.fetch('S3_ENCODING_KEY'),
            secret: ENV.fetch('S3_ENCODING_SECRET'),
            bucket: ENV.fetch('S3_ENCODING_BUCKET_NAME'),
            bucket_region: ENV.fetch('S3_ENCODING_REGION'),
            use: "zip_#{format}_#{t.id}",
            path: "/#{release.catalog}/#{t.isrc_code}/#{t.title.parameterize.underscore}.zip"
          })
        end

        ['aiff', 'flac', 'mp3', 'wav', 'ogg'].each do |format|
          steps << transloadit_client.step("store_#{t.id}_#{format}", '/s3/store', {
            key: ENV.fetch('S3_ENCODING_KEY'),
            secret: ENV.fetch('S3_ENCODING_SECRET'),
            bucket: ENV.fetch('S3_ENCODING_BUCKET_NAME'),
            bucket_region: ENV.fetch('S3_ENCODING_REGION'),
            use: "#{format}_#{t.id}",
            path: "/#{release.catalog}/#{t.isrc_code}/#{t.title.parameterize.underscore}.#{format}"
          })
        end
      end

      ['aiff', 'flac', 'mp3', 'wav'].each do |format|
        source = []
        release.tracks.each do |t|
          source << "#{format}_#{t.id}"
        end
        steps << transloadit_client.step("zip_collection_#{format}", '/file/compress', {
            format: 'zip',
            file_layout: 'simple',
            use: {steps: source,
                  bundle_steps: true }
          })
        steps << transloadit_client.step("store_zip_collection_#{format}", '/s3/store', {
          key: ENV.fetch('S3_ENCODING_KEY'),
          secret: ENV.fetch('S3_ENCODING_SECRET'),
          bucket: ENV.fetch('S3_ENCODING_BUCKET_NAME'),
          bucket_region: ENV.fetch('S3_ENCODING_REGION'),
          use: "zip_collection_#{format}",
          path: "/#{release.catalog}/#{release.id}/#{release.title.parameterize.underscore}.zip"
        })
      end

      assembly = transloadit_client.assembly(steps: steps)
      response = assembly.create!
      response.reload_until_finished!

      response.reload_until_finished!
      process_response response

    end

    def process_response(response)
      if !response.error? && response.completed?
        ['aiff', 'flac', 'mp3', 'wav'].each do |target|
          ReleaseFile.create(release: release,
                             format: "#{target}",
                             encode_status: :complete,
                             url_string: response['results']["zip_collection_#{target}"][0]['ssl_url'])
        end
        release.tracks.each do |t|
          ['aiff', 'flac', 'mp3', 'wav'].each do |target|
            TrackFile.create(track: t,
                             format: "zip_#{target}",
                             encode_status: :complete,
                             url_string: response['results']["zip_#{target}_#{t.id}"][0]['ssl_url'])
          end
          ['aiff', 'flac', 'mp3', 'wav', 'ogg'].each do |k|
            TrackFile.create(track: t,
                             format: k,
                             encode_status: :complete,
                             url_string: response['results']["#{k}_#{t.id}"][0]['ssl_url'])
          end
        end
        release.update(assembly_id: response[:assembly_id], assembly_complete: true)
      else
        release.update(assembly_id: response[:assembly_id], assembly_complete: false)
      end
    end
  end
end
