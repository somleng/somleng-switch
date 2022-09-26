require "yaml"

module EncryptedCredentials
  class EncryptedFile
    CIPHER = "aes-256-cbc".freeze
    DEFAULT_KEY_PATH = Pathname(File.expand_path("../config/master.key", __dir__))
    DEFAULT_FILE_PATH = Pathname(File.expand_path("../config/credentials.yml.enc", __dir__))

    attr_reader :file_path, :key_path

    def initialize(file_path: DEFAULT_FILE_PATH, key_path: DEFAULT_KEY_PATH)
      @file_path = file_path
      @key_path = key_path
    end

    def credentials
      content = read_credentials
      YAML.load(content)
    end

    def edit
      Tempfile.open([file_path.basename.to_s.chomp(".enc"), ".yml"]) do |tmp_file|
        if file_path.exist?
          tmp_file.write(read_credentials)
          tmp_file.flush
          tmp_file.rewind
        end

        system("#{ENV['EDITOR']} #{tmp_file.path}")

        updated_contents = tmp_file.read
        encrypted_content = encrypt(updated_contents)

        IO.binwrite("#{file_path}.tmp", Base64.strict_encode64(encrypted_content))
        FileUtils.mv("#{file_path}.tmp", file_path.to_path)
      end
    end

    private

    def read_credentials
      encrypted_content = Base64.strict_decode64(file_path.binread)
      decrypt(encrypted_content)
    end

    def key
      read_env_key || read_key_file || handle_missing_key
    end

    def read_env_key
      ENV["APP_MASTER_KEY"]
    end

    def read_key_file
      key_path.binread.strip if key_path.exist?
    end

    def handle_missing_key
      raise "Missing key"
    end

    def encrypt(content)
      cipher = OpenSSL::Cipher.new(CIPHER).encrypt
      cipher.key = [key].pack("H*")
      cipher.update(content) + cipher.final
    end

    def decrypt(content)
      cipher = OpenSSL::Cipher.new(CIPHER).decrypt
      cipher.key = [key].pack("H*")
      cipher.update(content) + cipher.final
    end
  end
end
