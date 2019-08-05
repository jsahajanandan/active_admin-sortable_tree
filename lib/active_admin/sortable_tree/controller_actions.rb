module ActiveAdmin::SortableTree
  module ControllerActions

    attr_accessor :sortable_options

    def sortable(options = {})
      options.reverse_merge! :sorting_attribute => :position,
                             :parent_method => :parent,
                             :children_method => :children,
                             :roots_method => :roots,
                             :tree => false,
                             :max_levels => 0,
                             :protect_root => false,
                             :collapsible => false, #hides +/- buttons
                             :start_collapsed => false,
                             :sortable => true

      # BAD BAD BAD FIXME: don't pollute original class
      @sortable_options = options

      # disable pagination
      config.paginate = false

      collection_action :sort, :method => :post do
        resource_name = ActiveAdmin::SortableTree::Compatibility.normalized_resource_name(active_admin_config.resource_name)

        records = resource_class.where(id: params[resource_name].flatten.uniq).index_by{|record| record.id.to_s}

        errors = []
        ActiveRecord::Base.transaction do
          params[resource_name].each_with_index do |(resource, parent_resource), position|
            if records[resource]
              records[resource].send "#{options[:sorting_attribute]}=", position
              if options[:tree]
                records[resource].send "#{options[:parent_method]}=", records[parent_resource]
              end
            end 
            errors << {records[resource].id => records[resource].errors} if !records[resource].save
          end
        end
        if errors.empty?
          head 200
        else
          render json: { error: { message: errors.map{|e| "#{e.keys.first} - #{e.values.first.full_messages.to_sentence}"}.join("\n") } }, status: 422
        end
      end

    end

  end

  ::ActiveAdmin::ResourceDSL.send(:include, ControllerActions)
end
