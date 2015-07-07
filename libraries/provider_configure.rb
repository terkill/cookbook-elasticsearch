class Chef
  class Provider
    # Chef Provider for configuring an elasticsearch instance
    class ElasticsearchConfigure < Chef::Provider::LWRPBase
      include ElasticsearchCookbook::Helpers
      def action_manage
        # Create ES directories
        #
        [path_conf, path_logs].each do |path|
          directory path do
            owner new_resource.user
            group new_resource.group
            mode 0755
            recursive true
            action :create
          end
        end

        # Create data path directories
        #
        data_paths = path_data.is_a?(Array) ? path_data : path_data.split(',')

        data_paths.each do |path|
          directory path.strip do
            owner new_resource.user
            group new_resource.group
            mode 0755
            recursive true
            action :create
          end
        end

        template 'elasticsearch.in.sh' do
          path "#{path_conf}/elasticsearch.in.sh"
          source new_resource.template_elasticsearch_env
          cookbook 'elasticsearch'
          owner new_resource.user
          group new_resource.group
          mode 0755
          variables(java_home: new_resource.java_home,
                    es_home: new_resource.es_home || new_resource.dir,
                    es_config: path_conf,
                    allocated_memory: new_resource.allocated_memory || compute_allocated_memory,
                    Xms: new_resource.allocated_memory || compute_allocated_memory,
                    Xmx: new_resource.allocated_memory || compute_allocated_memory,
                    Xss: new_resource.thread_stack_size,
                    gc_settings: new_resource.gc_settings,
                    env_options: new_resource.env_options)
        end

        # Create ES logging file
        #
        template 'logging.yml' do
          path   "#{path_conf}/logging.yml"
          source new_resource.template_logging_yml
          cookbook 'elasticsearch'
          owner new_resource.user
          group new_resource.group
          mode 0755
          variables(logging: new_resource.logging)
        end

        merged_configuration = default_configuration.merge(new_resource.configuration)
        merged_configuration[:_seen] = {} # magic state variable for what we've seen in a config

        # warn if someone is using symbols. we don't support.
        found_symbols = merged_configuration.keys.select { |s| s.is_a?(Symbol) && s != :_seen }
        unless found_symbols.empty?
          Chef::Log.warn("Please change the following to strings in order to work with this Elasticsearch cookbook: #{found_symbols.join(',')}")
        end

        template 'elasticsearch.yml' do
          path "#{path_conf}/elasticsearch.yml"
          source new_resource.template_elasticsearch_yml
          cookbook 'elasticsearch'
          owner new_resource.user
          group new_resource.group
          mode 0755
          helpers(ElasticsearchCookbook::Helpers)
          variables(config: merged_configuration)
        end
      end

      def path_conf
        format(new_resource.path_conf, new_resource.dir)
      end

      def path_data
        if new_resource.path_data.is_a?(Array)
          new_resource.path_data.map do |component|
            format(component, new_resource.dir)
          end
        else # non-array (string)
          format(new_resource.path_data, new_resource.dir)
        end
      end

      def path_logs
        format(new_resource.path_logs, new_resource.dir)
      end

      def default_configuration
        {
          # === NAMING
          'cluster.name' => 'elasticsearch',
          'node.name' => node.name,

          'path.conf' => path_conf,
          'path.data' => path_data,
          'path.logs' => path_logs,

          'action.destructive_requires_name' => true,
          'node.max_local_storage_nodes' => 1,

          'discovery.zen.ping.multicast.enabled' => true,
          'discovery.zen.minimum_master_nodes' => 1,
          'gateway.expected_nodes' => 1,

          'http.port' => 9200
        }
      end
    end
  end
end
