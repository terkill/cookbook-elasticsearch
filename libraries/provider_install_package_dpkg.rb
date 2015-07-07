class Chef
  class Provider
    # Chef Provider for installing or removing Elasticsearch from package
    # downloaded from elasticsearch.org and installed by dpkg. We break this out
    # because the package resource chooses an apt provider which cannot install
    # from a file. dpkg_package, however, can install from a file directly.
    class ElasticsearchInstallPackageDpkg < Chef::Provider::ElasticsearchInstallPackage
      provides :elasticsearch_install, platform_family: ['debian', 'ubuntu'] if respond_to?(:provides)

      def install_package(path, package_options)
        d = dpkg_package path do
          options package_options
          action :nothing
        end
        d.run_action(:install)

        new_resource.updated_by_last_action(d.updated_by_last_action?)
      end

      def remove_package(path)
        d = dpkg_package path do
          action :nothing
        end
        d.run_action(:remove)
        new_resource.updated_by_last_action(d.updated_by_last_action?)
      end

      class << self
        # supports the given resource and action (late binding)
        def supports?(resource, _action)
          resource.type == :package
        end
      end
    end
  end
end
