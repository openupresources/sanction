# Instances of Roles within the system. Uses double-sided polymorphism to attribute
# roles to principals over permissionables. Allows blanket class attributation.
#
class Sanction::Role < ActiveRecord::Base
  require_relative('role/definition')
  require_relative('role/error')

  #--------------------------------------------------#
  #                 Associations                     #
  #--------------------------------------------------#
  belongs_to :principal, :polymorphic => true
  belongs_to :permissionable, :polymorphic => true
  validates_presence_of :permissionable_type, :if => Proc.new {|r| !r.global?}
  validates_presence_of :name

  validate :valid_role_definition
  validate :uniqueness_of_intent, on: :create

  # Ensure the role is valid by definition
  def valid_role_definition
    Sanction::Role::Definition.valid_role_instance?(self)
  end

  # See if the intent of this role is captured by another role
  def uniqueness_of_intent
    conds = []
    conds << ["#{self.class.table_name}.principal_type = ? AND (#{self.class.table_name}.principal_id = ? OR #{self.class.table_name}.principal_id IS NULL)", principal_type, (principal_id || nil)]
    conds << ["#{self.class.table_name}.name = ?", name]

    if global?
      conds << ["#{self.class.table_name}.global = ?", true]

    else
      conds << ["#{self.class.table_name}.permissionable_type = ? AND (#{self.class.table_name}.permissionable_id = ? OR #{self.class.table_name}.permissionable_id IS NULL)", permissionable_type, (permissionable_id || nil)]
    end

    conditions = conds.map {|c| merge_conditions(c)}.join(" AND ")

    if Sanction::Role.exists?([conditions])
      errors.add_to_base("This role is already captured by another.")
      false
    else
      true
    end
  end

  def merge_conditions(*conditions)
    segments = []

    conditions.each do |condition|
      unless condition.blank?
        sql = ActiveRecord::Base.__send__(:sanitize_sql, condition)
        segments << sql unless sql.blank?
      end
    end

     "(#{segments.join(') AND (')})" unless segments.empty?
  end


  #--------------------------------------------------#
  #                    Scopes                        #
  #--------------------------------------------------#
  scope :global, -> { where(global: true) }

  # Expects an array of Permissionable instances or klasses
  scope( :over, lambda {|*permissionable_set|
    permissionables_by_klass = {}
    blanket_permissionables = []
    permissionable_set.each do |perm|
      if perm.is_a? Class
        blanket_permissionables << perm.name.to_s
      else
        permissionables_by_klass[perm.class.name.to_s] ||= []
        permissionables_by_klass[perm.class.name.to_s] << perm.id
      end
    end

    conds = []
    permissionables_by_klass.each do |(klass, ids)|
      conds << ["#{self.table_name}.permissionable_type = ? AND (#{self.table_name}.permissionable_id IN (?) OR #{self.table_name}.permissionable_id IS NULL)", klass, ids]
    end

    blanket_permissionables.each do |klass|
      conds << ["#{self.table_name}.permissionable_type = ?", klass]
    end
    conditions = conds.map { |c| merge_conditions(c) }.join(" OR ")

    {:select => "DISTINCT #{self.table_name}.*", :conditions => conditions}
  })

  # Expects an array of Principal instances or klasses
  scope( :for, lambda {|*principal_set|
    pricipals_by_klass = {}
    blanket_principals = []
    principal_set.each do |prin|
      if prin.is_a? Class
        blanket_principals << prin.name.to_s
      else
        pricipals_by_klass[prin.class.name.to_s] ||= []
        pricipals_by_klass[prin.class.name.to_s] << prin.id
      end
    end

    conds = []
    pricipals_by_klass.each do |(klass, ids)|
      conds << ["#{self.table_name}.principal_type = ? AND (#{self.table_name}.principal_id IN (?) OR #{self.table_name}.principal_id IS NULL)", klass, ids]
    end

    blanket_principals.each do |klass|
      conds << ["#{self.table_name}.principal_type = ?", klass]
    end
    conditions = conds.map { |c| merge_conditions(c) }.join(" OR ")

    {:select => "DISTINCT #{self.table_name}.*", :conditions => conditions}
  })

  #--------------------------------------------------#
  #                 Convenience                      #
  #--------------------------------------------------#
  def principal_klass
    self.principal_type.constantize
  end

  def permissionable_klass
    if self.permissionable_type
      self.permissionable_type.constantize
    else
      nil
    end
  end

  def principal_match?(instance_or_klass)
    if instance_or_klass.is_a? Class
      self.principal_type == instance_or_klass.name
    else
      self.principal_type == instance_or_klass.class.name and (self.principal_id.to_s == instance_or_klass.send(instance_or_klass.class.primary_key).to_s or self.principal_id == nil)
    end
  end

  def permissionable_match?(instance_or_klass)
    if instance_or_klass.is_a? Class
      self.permissionable_type == instance_or_klass.name
    else
      self.permissionable_type == instance_or_klass.class.name and (self.permissionable_id.to_s == instance_or_klass.send(instance_or_klass.class.primary_key).to_s or self.permissionable_id == nil)
    end
  end

  # Provides a basic description of the role.
  def describe
    prefix = ""
    if principal_id
      prefix = "#{principal_type.to_s.titleize} (#{principal_id})"
    else
      prefix = "ALL #{principal_type.to_s.pluralize.titleize}"
    end

    suffix = ""
    unless global?
      suffix = " for"
      if permissionable_id
        suffix << " #{permissionable_type.to_s.titleize} (#{permissionable_id})"
      else
        suffix << " ALL #{permissionable_type.to_s.pluralize.titleize}"
      end
    end

    role_defs = if self.permissionable_type
      permissionable_type_klass = (self.permissionable_type.blank? ? nil : self.permissionable_type.constantize)
      Sanction::Role::Definition.for(self.principal_type.constantize) & Sanction::Role::Definition.with(self.name) & Sanction::Role::Definition.over(permissionable_type_klass)
    else
      Sanction::Role::Definition.for(self.principal_type.constantize) & Sanction::Role::Definition.with(self.name)
    end
    permissions = role_defs.map(&:permissions).flatten.uniq

    suffix << (permissions.blank? ? "" : " implying #{permissions.join(', ')}")

    "#{prefix} has #{name.to_s.titleize}#{suffix}"
  end
end
