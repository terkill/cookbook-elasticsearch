class Chef
  class Provider
    # Chef Provider for installing or removing Elasticsearch from tarball
    # downloaded from elasticsearch.org and unpacked into (by default) /usr/local
    class ElasticsearchInstallSource < Chef::Provider::LWRPBase
      include ElasticsearchCookbook::Helpers
      provides :elasticsearch_install if respond_to?(:provides)

      def action_install
        converge_by("#{new_resource.name} - install source") do
          include_recipe 'ark'
          include_recipe 'curl'

          a = ark 'elasticsearch' do
            url   format(new_resource.source_url, new_resource.version)
            owner new_resource.owner
            group new_resource.group
            version new_resource.version
            has_binaries ['bin/elasticsearch', 'bin/plugin']
            checksum new_resource.source_checksum
            prefix_root   get_source_root_dir(new_resource, node)
            prefix_home   get_source_home_dir(new_resource, node)

            not_if do
              link   = "#{new_resource.dir}/elasticsearch"
              target = "#{new_resource.dir}/elasticsearch-#{new_resource.version}"
              binary = "#{target}/bin/elasticsearch"

              ::File.directory?(link) && ::File.symlink?(link) && ::File.readlink(link) == target && ::File.exist?(binary)
            end
            action :nothing
          end
          a.run_action(:install)
          new_resource.updated_by_last_action(a.updated_by_last_action?)
        end
      end

      def action_remove
        converge_by("#{new_resource.name} - remove source") do
          # remove the symlink to this version
          l = link "#{new_resource.dir}/elasticsearch" do
            action :nothing
            only_if do
              link   = "#{new_resource.dir}/elasticsearch"
              target = "#{new_resource.dir}/elasticsearch-#{new_resource.version}"

              ::File.directory?(link) && ::File.symlink?(link) && ::File.readlink(link) == target
            end
          end
          l.run_action(:delete)

          # remove the specific version
          d = directory "#{new_resource.dir}/elasticsearch-#{new_resource.version}" do
            action :nothing
          end
          d.run_action(:delete)

          new_resource.updated_by_last_action(l.updated_by_last_action? || d.updated_by_last_action?)
        end
      end

      class << self
        # supports the given resource and action (late binding)
        def supports?(resource, _action)
          resource.type == :source
        end
      end
    end
  end
end
