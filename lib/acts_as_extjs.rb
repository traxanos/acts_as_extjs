require 'rubygems'
require 'active_record'

module Extjs #:nodoc:
  module ActsAsExtjs #:nodoc:

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # activate gem on ar-model with acts_as_extjs
      #
      # -----
      # 
      # === Example:
      #   class User
      #     acts_as_extjs
      #   end
      # 
      def acts_as_extjs
        # empty named sop
        if Rails.version.at(0).to_i >= 3
          scope :extjs
        else
          named_scope :extjs
        end
        include Extjs::ActsAsExtjs::InstanceMethods
        extend Extjs::ActsAsExtjs::SingletonMethods
      end
    end

    module SingletonMethods
      # search on a model. the result is a hash that can use as json for extjs store
      #
      # +args+:: all options that you will use on active record finder with following extras
      #
      # -----
      #
      # === Options:
      # <tt>:fields</tt>::       List with hashes like extjs store fields.
      #                          <tt>:name</tt>::          Name off field. This will be call on row if not use an custom handler
      #                          <tt>:custom</tt>::        can use with Proc.new for own field content
      #                          <tt>:mapping</tt>::       Client side mapping by extjs store
      # <tt>:sort_mapping</tt>:: A Hash to map columns
      #                          :fieldname => "sqlfiels"
      #                          :user_name => "users.name"
      # <tt>:start</tt>::        start value from extjs paginate toolbar
      # <tt>:limit</tt>::        limit value from extjs paginate toolbar
      # <tt>:page</tt>::         page - will overritten if start/limit set
      # <tt>:per_page</tt>::     per_page - will overritten if start/limit set
      # <tt>:sort_by</tt>::      sort field. ignore fields that are not in sort_mapping and use this mapping
      # <tt>:group_by</tt>::     group field. ignore fields that are not in sort_mapping and use this mapping
      # <tt>:sort_dir</tt>::     direction: asc | desc
      # <tt>:group_dir</tt>::    direction: asc | desc
      # 
      # -----
      # 
      # === Example:
      #   render :json => User.extjs_result :fields = [{:name => :superid, :type => :id, :custom => Proc.new { |row| row.id }}]
      #
      def extjs_result(*args)
        options = args.extract_options!
        fields = options.delete(:fields)
        start = options.delete(:start).to_i
        limit = options.delete(:limit).to_i

        sort_mapping = options.delete(:sort_mapping)
        sort_by = options.delete(:sort_by)
        sort_dir = options.delete(:sort_dir)
        group_by = options.delete(:group_by)
        group_dir = options.delete(:group_dir)

        unless sort_mapping.blank?
          if not sort_by.blank? and sort_mapping.has_key?(sort_by.to_sym)
            if sort_dir.to_s.downcase == "desc"
              sort_dir = " DESC"
            else
              sort_dir = " ASC"
            end
            order = sort_mapping[sort_by.to_sym].to_s + sort_dir
          else
            order = 'created_at DESC'
          end

          if not group_by.blank? and sort_mapping.has_key?(group_by.to_sym)
            if group_dir.to_s.downcase == "desc"
              group_dir = " DESC"
            else
              group_dir = " ASC"
            end
            order = sort_mapping[group_by.to_sym].to_s + group_dir + ', ' + order
          end

          options[:order] = order if order
        end

        if limit.to_i > 0 or options[:per_page].to_i > 0
          options[:per_page] = limit if limit > 0
          options[:page] = (start > 0) ? (start/limit)+1 : 1
          result = self.extjs.paginate options
          total = result.total_entries
        else
          result = self.extjs.all options
          total = result.size
        end

        rows = []
        result.each do |result_row|
          row = {}
          fields.collect do |field|
            if field[:mapping].blank?
              if field[:custom].is_a? Proc
                row[field[:name]] = field[:custom].call(result_row)
              else
                row[field[:name]] = result_row.send(field[:name])
              end
              if row[field].is_a? ActiveSupport::TimeWithZone or row[field[:name]].is_a? DateTime or row[field[:name]].is_a? Time
                row[field[:name]] = row[field[:name]].strftime("%Y-%m-%d %H:%M:%S")
              end
            end
          end
          rows << row
        end

        return {
                :total => total,
                :data => rows,
                :metaData => {
                        :root => :data,
                        :messageProperty => 'message',
                        :successProperty => 'success',
                        :fields => fields,
                        :idProperty => :id,
                        :totalProperty => :total,
                        }
        }
      end
    end

    module InstanceMethods
      def extjs_error
        error = self.errors.first
        if error.nil?
          nil
        else
          if error.last.at(0) == '^'
            error.last.slice(1..-1)
          else
            "#{self.class.human_attribute_name(error.first)} #{error.last}"
          end
        end
      end

      def extjs_errors
        hash = {}
        self.errors.each do |error|
          if error.last.at(0) == '^'
            message = error.last.slice(1..-1)
          else
            message = "#{self.class.human_attribute_name(error.first)} #{error.last}"
          end
          hash["data[#{error.first}]"] = message
        end
        return hash
      end
    end
  end
end

ActiveRecord::Base.send(:include, Extjs::ActsAsExtjs)