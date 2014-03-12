class Chef
  class Provider
    class Deploy
      class Revision
        # if the first release fails, then we'll default to file system.
        # We should avoid falling back to filesystem unless we know for a fact
        # we have released before.
        def load_cache
          begin
            Chef::JSONCompat.from_json(Chef::FileCache.load("revision-deploys/#{new_resource.name}"))
          rescue Chef::Exceptions::FileNotFound
            # only return file system releases if we appear to have successfully
            # deployed in the past.
            return [] unless ::File.exists?(@new_resource.current_path)
            sorted_releases_from_filesystem
          end
        end

        def release_created(release_path)
          return unless ::File.exists?(@new_resource.current_path)
          release = ::File.readlink(@new_resource.current_path)
          sorted_releases {|r| r.delete(release); r << release }
        end

        def cleanup!
          release_created(release_path)

          super

          known_releases = sorted_releases

          Dir["#{new_resource.deploy_to}/releases/*"].each do |release_dir|
            unless known_releases.include?(release_dir)
              converge_by("Remove unknown release in #{release_dir}") do
                FileUtils.rm_rf(release_dir)
              end
            end
          end
        end
      end
    end
  end
end