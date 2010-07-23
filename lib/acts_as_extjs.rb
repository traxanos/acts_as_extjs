require 'rubygems'
require 'active_record'

module Extjs #:nodoc:
  module ActsAsExtjs #:nodoc:

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_extjs
        named_scope :extjs
        include Extjs::ActsAsExtjs::InstanceMethods
        extend Extjs::ActsAsExtjs::SingletonMethods
      end
    end

    module SingletonMethods
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
            order = sort_mapping[sort_by.to_sym] + sort_dir
          else
            order = 'created_at DESC'
          end


          if not group_by.blank? and sort_mapping.has_key?(group_by.to_sym)
            if group_dir.to_s.downcase == "desc"
              group_dir = " DESC"
            else
              group_dir = " ASC"
            end
            order = sort_mapping[group_by.to_sym] + group_dir + ', ' + order
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