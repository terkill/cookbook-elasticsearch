class Chef
  class Provider
    # Chef Provider for installing or removing Elasticsearch from package
    # downloaded from elasticsearch.org and installed by the package manager
    class ElasticsearchInstallPackage < Chef::Provider::LWRPBase
      include ElasticsearchCookbook::Helpers
      provides :elasticsearch_install, platform_family: ['rhel', 'fedora'] if respond_to?(:provides)

      def action_install
        converge_by("#{new_resource.name} - install package") do
          package_url = get_package_url(new_resource, node)
          filename = package_url.split('/').last
          checksum = get_package_checksum(new_resource, node)
          package_options = new_resource.package_options

          download_package(package_url, "#{Chef::Config[:file_cache_path]}/#{filename}", checksum)
          install_package("#{Chef::Config[:file_cache_path]}/#{filename}", package_options)
        end
      end

      def action_remove
        converge_by("#{new_resource.name} - remove package") do
          package_url = get_package_url(new_resource, node)
          filename = package_url.split('/').last

          remove_package("#{Chef::Config[:file_cache_path]}/#{filename}")
        end
      end

      class << self
        # supports the given resource and action (late binding)
        def supports?(resource, _action)
          resource.type == :package
        end
      end

      private

      def download_package(url, path, checksum)
        r = remote_file path do
          source url
          checksum checksum
          mode 00644
          action :nothing
        end
        r.run_action(:create)
        new_resource.updated_by_last_action(r.updated_by_last_action?)
      end

      def install_package(path, package_options)
        p = package path do
          options package_options
          action :nothing
        end
        p.run_action(:install)
        new_resource.updated_by_last_action(p.updated_by_last_action?)
      end

      def remove_package(path)
        p = package path do
          action :nothing
        end
        p.run_action(:remove)
        new_resource.updated_by_last_action(p.updated_by_last_action?)
      end
    end
  end
end
