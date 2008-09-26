# ActsAsVirtualAttribute
module Sixty4Bit
  module Acts
    module VirtualAttribute
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_virtual_attribute(*args, &proc)
          property = args[0]
          class_eval <<-EOT

          after_update :save_#{property}

          def new_#{property}_attributes=(attrs)
            attrs.each { |a| #{property}.build(a) }
          end

          def existing_#{property}_attributes=(attrs)
            #{property}.reject(&:new_record?).each do |a|
              attributes = attrs[a.id.to_s]
              if attributes
                a.attributes = attributes
              end
            end
          end

          def save_#{property}
            #{property}.each do |p|
              if p.should_destroy?
                p.destroy
              else
                p.save
              end
            end
          end

EOT


          destroy_method = <<REMOVE_CODE
          attr_accessor :should_destroy
          def should_destroy?
            should_destroy.to_i == 1
          end
REMOVE_CODE

          property.to_s.capitalize.singularize.constantize.class_eval(destroy_method)

          helper_method = <<HELPER_CODE
          def fields_for_#{property.to_s.singularize}(virt, &block)
            prefix = virt.new_record? ? 'new' : 'existing'
            fields_for("#{self.name.downcase}[#\{prefix\}_#{property}_attributes][]", virt, &block)
          end

          def link_to_remove_#{property.to_s.singularize}(name, container, form, &block)
            if form.object.new_record?
              link_to_function(name, "$(this).up('#\{container\}').remove()")
            else
              link_to_function(name, "$(this).up('#\{container\}').hide(); $(this).next('.should_destroy').value = 1") +
              form.hidden_field(:should_destroy, :value => 0, :class => 'should_destroy') 
            end
          end
HELPER_CODE

          helper_name = self.name.pluralize + "Helper"
          helper_name.constantize.class_eval(helper_method)

          include Sixty4Bit::Acts::VirtualAttribute::InstanceMethods
          extend Sixty4Bit::Acts::VirtualAttribute::SingletonMethods
        end
      end

      module InstanceMethods
      end

      module SingletonMethods
      end

    end
  end
end

ActiveRecord::Base.send(:include, Sixty4Bit::Acts::VirtualAttribute)