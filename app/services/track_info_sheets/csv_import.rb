module TrackInfoSheets
  class CsvImport
    require 'addressable/uri'
    require 'creek'
    attr_reader :file
    # SKIP_LINES = 2

    def initialize(bulk_track_info_sheet)
      sheet = bulk_track_info_sheet
      @file = sheet.open
    end

    def call
      puts '--'*200
      puts 'Import Start'
      creek = Creek::Book.new file
      sheet = creek.sheets[0]
      puts sheet.simple_rows.count
      sheet.simple_rows.drop(1).each do |row|
        if row != {}
          extract_value row
          # puts row['A'].inspect
          # puts row['G'].to_s.inspect
        end
      end
      # data = SmarterCSV.process(file)
      # puts data.inspect
      # csv_records do |records|
      #   puts '--'*500
      #   puts records.inspect
      # end
      puts '--'*200
      puts 'Import End'
    end

    def extract_value(row)
      release = Release.includes(:tracks).find_by(catalog: row['B'])
      if release.nil?
        release = Release.new(catalog: row['B'],
                              title: 'asd',
                              release_date: row['G'].to_datetime,
                              published_at: DateTime.now,
                              upc_code: '',
                              text: '',
                              artist: row['C'])
        release.remote_avatar_url = format_dropbox_url(row['AE'])
        release.save!
      end
      save_track(release, row)
    end

    def save_track(release, row)
      track_url = format_dropbox_url(row['AD'])
      if Track.find_by(uri_string: track_url).nil?
        track = Track.new
        track.title = row['D']
        track.track_number = release.tracks.count+1
        track.release = release
        track.isrc_code = row['L']
        track.artist = row['E']
        track.uri_string = track_url
        track.genre = row['M']
        track.save!
        save_track_info(track, row)
      end
    end

    def save_track_info(track, row)
      track.track_info.update(label_name: row['A'],
                              catalog: row['B'],
                              release_artist: row['C'],
                              track_title: row['D'],
                              track_artist: row['E'],
                              release_name: row['F'],
                              release_date: row['G'].to_datetime,
                              mix_name: row['H'],
                              remixer: row['I'],
                              track_time: row['J'],
                              barcode: row['K'],
                              isrc: row['L'],
                              genre: row['M'],
                              release_written_by: row['N'],
                              release_producer: row['O'],
                              track_publisher: row['P'],
                              track_written_by: row['Q'],
                              track_produced_by: row['R'],
                              vocals_m: boolean_value(row['S']),
                              vocals_f: boolean_value(row['T']),
                              upbeat_drivind_energetic: boolean_value(row['U']),
                              sad_moody_dark: boolean_value(row['V']),
                              fun_playfull_quirky: boolean_value(row['W']),
                              sentimental_love: boolean_value(row['X']),
                              big_buildups_sweeps: boolean_value(row['Y']),
                              celebratory_party_vibe: boolean_value(row['Z']),
                              inspiring_uplifting: boolean_value(row['AA']),
                              chill_mellow: boolean_value(row['AB']),
                              lyrics: row['AC']
                            )
    end

    def boolean_value(value)
      if value == '0' || value == ''
        false
      else
        true
      end
    end

    def format_dropbox_url(u)
      url = Addressable::URI.parse(u)
      params = url.query_values
      params.delete('dl')
      url.query_values = params
      url.to_s + 'raw=1'
    end

  end
end
