class Chef
  class Provider
    # Chef Provider for creating a user and group for Elasticsearch
    class ElasticsearchUser < Chef::Provider::LWRPBase
      # true because we use converge_by
      def whyrun_supported?
        true
      end

      def action_create
        converge_by("create elasticsearch_user resource #{new_resource.name}") do
          g = group new_resource.groupname do
            gid new_resource.gid
            action :nothing
            system true
          end
          g.run_action(:create)

          u = user new_resource.username do
            comment new_resource.comment
            home    home_directory_path
            shell   new_resource.shell
            uid     new_resource.uid
            gid     new_resource.groupname
            supports manage_home: false
            action  :nothing
            system true
          end
          u.run_action(:create)

          h = bash 'remove the elasticsearch user home' do
            user    'root'
            code    "rm -rf #{home_directory_path}"
            not_if  { ::File.symlink?(home_directory_path) }
            only_if { ::File.directory?(home_directory_path) }
            action :nothing
          end
          h.run_action(:run)

          new_resource.updated_by_last_action(
            g.updated_by_last_action? ||
            u.updated_by_last_action? ||
            h.updated_by_last_action?
          )
        end
      end

      def action_remove
        converge_by("remove elasticsearch_user resource #{new_resource.name}") do
          # delete user before deleting the group
          u = user new_resource.username do
            action  :nothing
          end
          u.run_action(:remove)

          g = group new_resource.groupname do
            action :nothing
          end
          g.run_action(:remove)

          new_resource.updated_by_last_action(
            g.updated_by_last_action? ||
            u.updated_by_last_action?
          )
        end
      end

      def home_directory_path
        new_resource.homedir || ::File.join(new_resource.homedir_parent, new_resource.homedir_name)
      end
    end
  end
end
