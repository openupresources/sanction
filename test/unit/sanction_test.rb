require File.dirname(__FILE__) + '/../test_helper.rb'

class SanctionTest < Test::Unit::TestCase
  def setup
    Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', 'people')
    Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', 'magazines')

    # Set up config --
    Sanction.configure do |config|
      config.principals      = [Person]
      config.permissionables = [Person, Magazine, Magazines::Article, Tabloid]
      
      config.role :reader, Person => Magazine, :having => [:can_read]
      config.role :editor, Person => Magazine, :having => [:can_edit],  :includes => [:reader]
      config.role :writer, Person => Magazine, :having => [:can_write], :includes => [:reader]
      config.role :owner,  Person => Magazine, :includes => [:editor, :writer]

      config.role :tester, Person => :all

      config.role :super_user, Person => :global, :having => :anything
      config.role :admin,      Person => :global
    end
  end

#--------------------------------------------------#
#                   Response                       #
#--------------------------------------------------#
  def test_people_respond_to_grant
    assert Person.respond_to?( :grant )
    assert Person.first.respond_to?( :grant )
  end

  def test_people_respond_to_has
    assert Person.respond_to?( :has )
    assert Person.respond_to?( :has? )
   
    assert Person.first.respond_to?( :has )
    assert Person.first.respond_to?( :has? )
  end

  def test_people_respond_to_over
    assert Person.respond_to?( :over )
    assert Person.respond_to?( :over? )

    assert Person.first.respond_to?( :over )
    assert Person.first.respond_to?( :over? )
  end
  
  def test_people_respond_to_sentence_composition
    assert Person.has(:any).respond_to?( :over )
    assert Person.has(:any).respond_to?( :over? )
   
    assert Person.over(:any).respond_to?( :has )
    assert Person.over(:any).respond_to?( :has? ) 
    
    assert Person.first.has(:any).respond_to?( :over )
    assert Person.first.has(:any).respond_to?( :over? )
   
    assert Person.first.over(:any).respond_to?( :has )
    assert Person.first.over(:any).respond_to?( :has? ) 
  end

  def test_magazines_respond_to_authorize
    assert Magazine.respond_to?( :authorize )
    assert Magazine.first.respond_to?( :authorize )
  end

  def test_magazines_respond_to_with
    assert Magazine.respond_to?( :with )
    assert Magazine.respond_to?( :with? )
   
    assert Magazine.first.respond_to?( :with )
    assert Magazine.first.respond_to?( :with? )
  end

  def test_magazines_respond_to_for
    assert Magazine.respond_to?( :for )
    assert Magazine.respond_to?( :for? )

    assert Magazine.first.respond_to?( :for )
    assert Magazine.first.respond_to?( :for? )
  end

  def test_magazines_respond_to_sentence_composition
    assert Magazine.with(:any).respond_to?( :for )
    assert Magazine.with(:any).respond_to?( :for? )
   
    assert Magazine.for(:any).respond_to?( :with )
    assert Magazine.for(:any).respond_to?( :with? ) 
    
    assert Magazine.first.with(:any).respond_to?( :for )
    assert Magazine.first.with(:any).respond_to?( :for? )
   
    assert Magazine.first.for(:any).respond_to?( :with )
    assert Magazine.first.for(:any).respond_to?( :with? ) 
  end

  def test_magazine_scoped_article_responds_to_permissionable_methods
    assert Magazines::Article.respond_to?( :with )
    assert Magazines::Article.respond_to?( :with? )

    assert Magazines::Article.respond_to?( :for )
    assert Magazines::Article.respond_to?( :for? )

    assert Magazines::Article.respond_to?( :total )
  end

#--------------------------------------------------#
#                  Scenarios                       #
#--------------------------------------------------#
  def test_grant_all_people_reader_for_magazines
    assert Person.grant(:reader, Magazine)
    assert Sanction::Role.count(:all) == 1

    # People over Magazines
    assert Person.has(:reader).total == Person.count(:all)
    assert Person.has(:reader).over(Magazine).total == Person.count(:all) 
    assert Person.has(:reader).over(Magazine.first).total == Person.count(:all)
   
    assert Person.first.has?(:reader)
    assert Person.first.has(:reader).over?(Magazine)
    assert Person.first.has(:reader).over?(Magazine.first)

    # Magazines for People
    assert Magazine.for(Person).total == Magazine.count(:all)
    assert Magazine.for(Person).with(:reader).total == Magazine.count(:all)
    assert Magazine.for(Person.first).with(:reader).total == Magazine.count(:all)

    assert Magazine.first.for?(Person)
    assert Magazine.first.for(Person).with?(:reader)
    assert Magazine.first.for(Person.first).with?(:reader)

    assert Person.revoke(:reader, Magazine)
    assert Sanction::Role.count(:all) == 0
  end

  def test_grant_single_person_reader_for_all_magazines
    assert Person.first.grant(:reader, Magazine)
    assert Sanction::Role.count(:all) == 1

    assert Person.first.has?(:reader)
    assert Person.first.has(:reader).over?(Magazine)
    assert Person.first.has(:reader).over?(Magazine.first)
    assert Person.first.has(:reader).over?(Magazine.last)
 
    assert !Person.last.has?(:reader)
    assert !Person.last.has(:reader).over?(Magazine)
    assert !Person.last.has(:reader).over?(Magazine.first)
    assert !Person.last.has(:reader).over?(Magazine.last) 
  
    assert Person.first.revoke(:reader, Magazine)
    assert Sanction::Role.count(:all) == 0
  end

  def test_grant_single_person_reader_for_single_magazine
    assert Person.first.grant(:reader, Magazine.first)
    assert Sanction::Role.count(:all) == 1

    assert Person.has(:reader).total == 1
    assert Person.has(:reader).include?( Person.first )

    assert Person.has(:reader).over(Magazine).total == 1
    assert Person.has(:reader).over(Magazine).include?( Person.first )

    assert Person.has(:reader).over(Magazine.first).total == 1
    assert Person.has(:reader).over(Magazine.first).include?( Person.first )

    assert Person.has(:reader).over(Magazine.last).total == 0
  
    assert Person.first.has?(:reader)
    assert Person.first.has(:reader).over?(Magazine)
    assert Person.first.has(:reader).over?(Magazine.first)
    assert !Person.first.has(:reader).over?(Magazine.last)

    assert Person.first.revoke(:reader, Magazine.first)
    assert Sanction::Role.count(:all) == 0
  end
  
  def test_grant_all_people_reader_for_single_magazine
    assert Person.grant(:reader, Magazine.first)
    assert Sanction::Role.count(:all) == 1

    assert Magazine.for(Person).with(:reader).total == 1
    assert Magazine.for(Person).with(:reader).include?( Magazine.first )

    assert Person.first.has?(:reader)
    assert Person.first.has(:reader).over?(Magazine.first)
    assert !Person.first.has(:reader).over?(Magazine.last)
     
    assert Person.revoke(:reader, Magazine.first)
    assert Sanction::Role.count(:all) == 0
  end


  def test_authorize_all_magazines_reader_for_people
    assert Magazine.authorize(:reader, Person)
    assert Sanction::Role.count(:all) == 1

    assert Magazine.for(Person).total == Magazine.count(:all)
    assert Magazine.for(Person).with(:reader).total == Magazine.count(:all)

    assert Magazine.for?(Person.first)
    assert Magazine.for(Person.first).with?(:reader)
    
    assert Magazine.first.for?(Person)
    assert Magazine.first.for(Person).with?(:reader)
    assert Magazine.first.for(Person.first).with?(:reader)

    assert Magazine.unauthorize(:reader, Person)
    assert Sanction::Role.count(:all) == 0
  end

  def test_authorize_single_magazine_reader_for_people
    assert Magazine.first.authorize(:reader, Person)
    assert Sanction::Role.count(:all) == 1

    assert Magazine.first.for?(Person)
    assert Magazine.first.for(Person).with?(:reader)
    assert Magazine.first.for(Person.first).with?(:reader)
  
    assert !Magazine.last.for?(Person)
    assert !Magazine.last.for(Person).with?(:reader)
    assert !Magazine.last.for(Person.first).with?(:reader)
   
    assert Magazine.first.unauthorize(:reader, Person)
    assert Sanction::Role.count(:all) == 0
  end

  def test_authorize_single_magazine_reader_for_single_person
    assert Magazine.first.authorize(:reader, Person.first)
    assert Sanction::Role.count(:all) == 1

    assert Magazine.first.for?(Person)
    assert Magazine.first.for(Person).with?(:reader)
    assert Magazine.first.for(Person.first).with?(:reader)
  
    assert !Magazine.first.for?(Person.last)
    assert !Magazine.first.for(Person.last).with?(:reader)

    assert Magazine.first.unauthorize(:reader, Person.first)
    assert Sanction::Role.count(:all) == 0
  end

  def test_authorize_all_magazines_for_single_person
    assert Magazine.authorize(:reader, Person)
    assert Sanction::Role.count(:all) == 1

    assert Magazine.for(Person).total == Magazine.count(:all)
    assert Magazine.for(Person).with(:reader).total == Magazine.count(:all)

    assert Magazine.for(Person.first).total == Magazine.count(:all)
    assert Magazine.for(Person.first).with(:reader).total == Magazine.count(:all)

    assert Magazine.first.for?(Person)
    assert Magazine.first.for(Person).with?(:reader)

    assert Magazine.first.for?(Person.first)
    assert Magazine.first.for(Person.first).with?(:reader)

    assert Magazine.unauthorize(:reader, Person)
    assert Sanction::Role.count(:all) == 0
  end

#--------------------------------------------------#
#               Multiplicity _all                  #
#--------------------------------------------------#
  def test_multiple_roles
    assert Person.first.grant(:editor, Magazine.first)
    assert Sanction::Role.count(:all) == 1

    assert Person.first.grant(:writer, Magazine.first)
    assert Sanction::Role.count(:all) == 2

    assert (Person.has(:editor) & Person.has(:writer)).size == 1
    assert (Person.has(:editor) & Person.has(:writer)).include?( Person.first )

    assert Person.has?(:editor)
    assert Person.has?(:writer)

    assert Person.has(:editor).over?(Magazine)
    assert Person.has(:writer).over?(Magazine)

    assert Person.has(:editor).over?(Magazine.first)
    assert Person.has(:writer).over?(Magazine.first)

    assert !Person.has(:editor).over?(Magazine.last)
    assert !Person.has(:writer).over?(Magazine.last)

    assert Person.first.revoke(:editor, Magazine.first)
    assert Sanction::Role.count(:all) == 1
    
    assert Person.first.revoke(:writer, Magazine.first)
    assert Sanction::Role.count(:all) == 0
  end

  def test_role_over_multiple_permissionables
    assert Person.first.grant(:editor, Magazine.first)
    assert Person.first.grant(:editor, Magazine.last)
    assert Sanction::Role.count(:all) == 2


    assert Person.first.revoke(:editor, Magazine.first)
    assert Person.first.revoke(:editor, Magazine.last)
    assert Sanction::Role.count(:all) == 0
  end

#--------------------------------------------------#
#               Role Options                       #
#--------------------------------------------------#
  def test_global_roles
    assert !Person.first.grant(:super_user, Magazine) 
    assert Sanction::Role.count(:all) == 0
 
    assert Person.first.grant(:super_user)
    assert Sanction::Role.count(:all) == 1

    assert Person.first.has?(:super_user)
    
    assert Person.first.revoke(:super_user)
    assert Sanction::Role.count(:all) == 0
  end

  def test_having_anything
    assert Person.first.grant(:super_user)
    assert Sanction::Role.count(:all) == 1

    assert Person.last.grant(:admin)
    assert Sanction::Role.count(:all) == 2
  
    assert Person.has?(:super_user)
    assert Person.has(:super_user).size == 1
    assert Person.has(:super_user).include?( Person.first )

    assert Person.first.has?(:super_user)
    assert Person.first.has?(:anything)
    assert Person.first.has?(:whatever)
    
    assert Person.last.has?(:admin)
    assert !Person.last.has?(:whatever)
 
    assert Person.last.revoke(:admin)
    assert Sanction::Role.count(:all) == 1

    assert Person.first.revoke(:super_user)
    assert Sanction::Role.count(:all) == 0
  end
  
  def test_permissions
    roles = [:reader, :editor, :writer, :owner]
    Person.all.each_with_index do |person, index|
      assert person.grant(roles[index], Magazine.first)  
    end
    assert Sanction::Role.count(:all) == 4

    assert Person.has(:can_read).size == 4
    Person.all.each do |person|
      assert Person.has(:can_read).include?( person )
      assert Person.has(:can_read).over(Magazine).include?( person )
      assert Person.has(:can_read).over(Magazine.first).include?( person )
    end

    Person.all.each_with_index do |person, index|
      assert person.revoke(roles[index], Magazine.first)  
    end
    assert Sanction::Role.count(:all) == 0
  end

  def test_includes
    assert Person.first.grant(:owner, Magazine.first)
    assert Sanction::Role.count(:all) == 1

    assert Person.first.has?(:reader)
    assert Person.first.has(:reader).over?(Magazine.first)

    assert Person.first.has?(:editor)
    assert Person.first.has(:editor).over?(Magazine.first)

    assert Person.first.has?(:writer)
    assert Person.first.has(:writer).over?(Magazine.first)

    assert Person.first.has?(:owner)
    assert Person.first.has(:owner).over?(Magazine.first)

    assert Person.first.revoke(:owner, Magazine.first)
    assert Sanction::Role.count(:all) == 0
  end

  def test_uniqueness_of_intent
    assert Person.grant(:reader, Magazine)
    assert Sanction::Role.count(:all) == 1

    assert !Person.grant(:reader, Magazine)
    assert Sanction::Role.count(:all) == 1

    assert !Person.first.grant(:reader, Magazine)
    assert Sanction::Role.count(:all) == 1

    assert !Person.last.grant(:reader, Magazine.first)
    assert Sanction::Role.count(:all) == 1

    assert Person.revoke(:reader, Magazine)
    assert Sanction::Role.count(:all) == 0
  end

  def test_any
    assert Person.grant(:reader, Magazine)
    assert Sanction::Role.count(:all) == 1

    assert Person.has(:any).total == Person.count(:all)
    assert Person.over(:any).total == Person.count(:all)
    assert Person.has(:any).over(:any).total == Person.count(:all)

    assert Magazine.for(:any).total == Magazine.count(:all) 
    assert Magazine.with(:any).total == Magazine.count(:all)
    assert Magazine.for(:any).with(:any).total == Magazine.count(:all)  
  
    assert Person.revoke(:reader, Magazine)
    assert Sanction::Role.count(:all) == 0
  end

  def test_instance_grant_should_not_result_in_universal_application
    assert_raise(Sanction::Role::Error::UnknownPrincipal) { Person.new.grant(:reader, Magazine) }
    assert_raise(Sanction::Role::Error::UnknownPermissionable) { Person.grant(:reader, Magazine.new) }
  end
  
  def test_instance_authorize_should_not_result_in_universal_application
    assert_raise(Sanction::Role::Error::UnknownPermissionable) { Magazine.new.authorize(:reader, Person) }
    assert_raise(Sanction::Role::Error::UnknownPrincipal) { Magazine.authorize(:reader, Person.new) }
  end

  def test_instance_revoke_should_not_result_in_universal_deletion
    assert_raise(Sanction::Role::Error::UnknownPrincipal) { Person.new.revoke(:reader, Magazine) }
    assert_raise(Sanction::Role::Error::UnknownPermissionable) { Person.revoke(:reader, Magazine.new) }
  end

  def test_instance_unauthorize_should_not_result_in_universal_deletion
    assert_raise(Sanction::Role::Error::UnknownPermissionable) { Magazine.new.unauthorize(:reader, Person) }
    assert_raise(Sanction::Role::Error::UnknownPrincipal) { Magazine.unauthorize(:reader, Person.new) }
  end

  def test_removal_of_principal_instance
    assert Person.grant(:reader, Magazine)

    person = Person.create
    assert person.grant(:editor, Magazine)
    assert Sanction::Role.count(:all) == 2

    person.destroy

    assert Sanction::Role.count(:all) == 1
    assert Person.revoke(:reader, Magazine)
    assert Sanction::Role.count(:all) == 0
  end

  def test_removal_of_permissionable_instance
     assert Magazine.authorize(:reader, Person)
    
     magazine = Magazine.create
     assert magazine.authorize(:editor, Person)
   
     magazine.destroy
    
     assert Sanction::Role.count(:all) == 1
     assert Magazine.unauthorize(:reader, Person)
     assert Sanction::Role.count(:all) == 0
  end

#--------------------------------------------------#
#               Associations                       #
#--------------------------------------------------#

  def test_principal_roles_and_permissionable_roles_assoc
    person = Person.create
    magazine = Magazine.create
 
    assert person.grant(:editor, magazine) 
    assert person.principal_roles.size == 1
    assert magazine.permissionable_roles.size == 1

    assert person.principal_roles.over(magazine).size == 1
    assert magazine.permissionable_roles.for(person).size == 1
    
    assert person.principal_roles.over(magazine).map(&:name).include?( "editor" )
    assert magazine.permissionable_roles.for(person).map(&:name).include?( "editor" )

    assert person.revoke(:editor, magazine)
  
    magazine.destroy
    person.destroy
  end

  def test_eager_loading_mechanism
    person = Person.first
    magazine = Magazine.first

    person.grant(:editor, Magazine)
   
    p = Person.find(:first, :conditions => ["unique_id = ?",  person.unique_id], :preload_roles => true)
    m = Magazine.find(:first, :conditions => ["id = ?", magazine.id], :preload_roles => true)
    
    assert p.principal_roles_loaded?

    person.revoke(:editor, Magazine)
    person.reload

    assert !person.has?(:editor)
    assert !person.has(:editor).over?(Magazine)
    assert p.has?(:editor)     
    assert p.has(:editor).over?(Magazine)
    assert !magazine.with?(:editor)
    assert !magazine.for(person).with?(:editor)
    assert m.with?(:editor)
    assert m.for?(person)
    assert m.for(person).with?(:editor)
  end
  
  def test_eager_loading_with_permissions
    person = Person.first
    magazine = Magazine.first
    
    person.grant(:owner, Magazine)
 
    p = Person.find(:first, :conditions => ["unique_id = ?", person.unique_id], :preload_roles => true)
    m = Magazine.find(:first, :conditions => ["id = ?", magazine.id], :preload_roles => true)

    assert p.principal_roles_loaded?
    assert m.permissionable_roles_loaded?

    person.revoke(:owner, Magazine)
  
    assert !person.has?(:can_edit)
    assert !person.has(:editor).over?(Magazine)
    assert p.has?(:can_edit)
    assert p.has(:editor).over?(Magazine)
    assert !magazine.with?(:can_edit)
    assert !magazine.for(Person).with?(:can_edit)
    assert m.with?(:can_edit)
    assert m.with?(:any)
    assert m.for?(:any)
    assert m.for(:any).with?(:can_edit)
    assert m.for(Person).with?(:can_edit)
  end

  def test_blank_result_from_eager_loading
    person = Person.first
    
    person.grant(:owner, Magazine)
  
    p = Person.find(:first, :conditions => ["unique_id = ?", person.unique_id], :preload_roles => true)

    person.revoke(:owner, Magazine)

    assert p.has?(:can_edit)
    assert !p.has?(:non_permission)
    assert !p.has(:non_permission).over?(Magazine)
  end
  
  def test_single_result_from_eager_loading
    person = Person.first
    person.grant(:editor, Magazine)

    p = Person.first(:preload_roles => true)

    assert p.has?(:any) == person.has?(:any)
    assert (p.has(:any) - person.has(:any)).size == 0

    person.revoke(:editor, Magazine)
  end

  def test_iteration_of_preloaded_roles
    Person.grant(:reader, Magazine)

    people = Person.find(:all, :preload_roles => true)    

    Person.revoke(:reader, Magazine)

    people.each do |p|
      assert p.has?(:reader)
      assert p.has(:reader).over?(Magazine)
      assert !p.has?(:some_non_role)
      assert !p.has(:some_non_role).over?(:any)
      assert !p.has(:some_non_role).over?(Magazine)
    end

    assert !Person.first.has?(:reader)
  end

  def test_preload_roles_with_multiples
     Person.first.grant(:writer, Magazine.first)
     Person.first.grant(:editor, Magazine.last)
 
     person = Person.first :preload_roles => true
   
     Person.first.revoke(:writer, Magazine.first)
     Person.first.revoke(:editor, Magazine.last)

     assert person.has(:writer).over?(Magazine.first)
     assert person.has(:editor).over?(Magazine.last)
     assert !person.has(:editor).over?(Magazine.first)
     assert !person.has(:writer).over?(Magazine.last)
  end

  def test_preload_roles_with_any
    Person.first.grant(:reader, Magazine.first)

    person = Person.first :preload_roles => true
    magazine = Magazine.first :preload_roles => true
   
    Person.first.revoke(:reader, Magazine.first)
  
    assert person.has?(:any)
    assert magazine.with?(:any)
    assert person.has(:any).over?(:any)
    assert magazine.for(:any).with?(:any)
  end

  def test_blank_array_result_with_principal_permissionable
    Person.last.grant(:tester, Person.first)

    person = Person.first :preload_roles => true
    
    Person.last.revoke(:tester, Person.first)

    assert !person.with(:non_role).for?(:any)
    assert person.with(:tester).for?(:any)
  end
end
