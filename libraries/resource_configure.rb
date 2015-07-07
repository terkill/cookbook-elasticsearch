class Chef
  class Resource
    # Chef Resource for configuring an Elasticsearch node
    #
    class ElasticsearchConfigure < Chef::Resource::LWRPBase
      resource_name :elasticsearch_configure

      actions(:manage, :remove)
      default_action :manage

      attribute(:dir, kind_of: String, default: '/usr/local')

      attribute(:path_conf, kind_of: String, default: '%s/etc/elasticsearch')
      attribute(:path_data, kind_of: String, default: '%s/var/data/elasticsearch')
      attribute(:path_logs, kind_of: String, default: '%s/var/log/elasticsearch')

      attribute(:user, kind_of: String, default: 'elasticsearch')
      attribute(:group, kind_of: String, default: 'elasticsearch')

      attribute(:template_elasticsearch_env, kind_of: String, default: 'elasticsearch.in.sh.erb')
      attribute(:template_elasticsearch_yml, kind_of: String, default: 'elasticsearch.yml.erb')
      attribute(:template_logging_yml, kind_of: String, default: 'logging.yml.erb')

      attribute(:logging, kind_of: Hash, default: {})

      attribute(:java_home, kind_of: String, default: nil)
      attribute(:es_home, kind_of: String, default: nil)

      attribute(:allocated_memory, kind_of: String, default: nil)
      attribute(:thread_stack_size, kind_of: String, default: '256k')
      attribute(:env_options, kind_of: String, default: '')
      attribute(:gc_settings, kind_of: String, default:
        <<-CONFIG
          -XX:+UseParNewGC
          -XX:+UseConcMarkSweepGC
          -XX:CMSInitiatingOccupancyFraction=75
          -XX:+UseCMSInitiatingOccupancyOnly
          -XX:+HeapDumpOnOutOfMemoryError
          -XX:+DisableExplicitGC
        CONFIG
               )

      # These are the default settings. Most of the time, you want to override the `configuration` attribute below.
      #
      attribute(:default_configuration, kind_of: Hash, default: nil)

      # These settings are merged with the `default_configuration` attribute,
      # allowing you to override and set specific settings.
      #
      attribute(:configuration, kind_of: Hash, default: {})
    end
  end
end
