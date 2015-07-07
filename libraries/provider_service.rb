class Chef
  class Provider
    # Chef Provider for configuring an elasticsearch service in the init system
    class Provider::ElasticsearchService < Chef::Provider::LWRPBase
      # true because we use converge_by
      def whyrun_supported?
        true
      end

      def action_remove
      end

      def action_configure
        res_pid_dir = directory new_resource.pid_path do
          mode '0755'
          recursive true
          action :nothing
        end
        res_pid_dir.run_action(:create)

        # Create service
        #
        res_init_templ = template "/etc/init.d/#{new_resource.service_name}" do
          source 'elasticsearch.init.erb'
          cookbook 'elasticsearch'
          owner 'root'
          mode 0755
          variables(nofile_limit: new_resource.nofile_limit,
                    memlock_limit: new_resource.memlock_limit,
                    pid_file: new_resource.pid_file || "#{new_resource.pid_path}/#{node.name.to_s.gsub(/\W/, '_')}.pid",
                    path_conf: new_resource.path_conf,
                    user: new_resource.user,
                    platform_family: node.platform_family,
                    bindir: new_resource.bindir,
                    http_port: 9200, # TODO: does the init script really need this?
                    node_name: new_resource.node_name || node.name,
                    service_name: new_resource.service_name,
                    args: new_resource.args)
          action :nothing
        end
        res_init_templ.run_action(:create)

        # Increase open file and memory limits
        #
        res_bash_limits = bash 'enable user limits' do
          user 'root'

          code <<-END.gsub(/^              /, '')
            echo 'session    required   pam_limits.so' >> /etc/pam.d/su
          END

          not_if { ::File.read('/etc/pam.d/su').match(/^session    required   pam_limits\.so/) }
          action :nothing
        end
        res_bash_limits.run_action(:run)

        res_file_limits = file '/etc/security/limits.d/10-elasticsearch.conf' do
          content <<-END.gsub(/^          /, '')
            #{new_resource.user} - nofile    #{new_resource.nofile_limit}
            #{new_resource.user} - memlock   #{new_resource.memlock_limit}
          END
          action :nothing
        end
        res_file_limits.run_action(:create)

        res_svc = service new_resource.service_name do
          supports status: true, restart: true
          action :nothing
        end
        res_svc.run_action(:enable)
        new_resource.updated_by_last_action(res_svc.updated_by_last_action?)
      end
    end
  end
end
