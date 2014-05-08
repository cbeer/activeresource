module ActiveResource::Associations
  extend ActiveSupport::Concern

  module Builder
    autoload :Association, 'active_resource/associations/builder/association'
    autoload :SingularAssociation,   'active_resource/associations/builder/singular_association'
    autoload :HasMany,     'active_resource/associations/builder/has_many'
    autoload :HasOne,      'active_resource/associations/builder/has_one'
    autoload :BelongsTo,   'active_resource/associations/builder/belongs_to'
  end

  autoload :Association,     'active_resource/associations/association'
  autoload :CollectionAssociation,     'active_resource/associations/collection_association'
  autoload :SingularAssociation,     'active_resource/associations/singular_association'
  autoload :HasManyAssociation,     'active_resource/associations/has_many_association'
  autoload :HasOneAssociation,     'active_resource/associations/has_one_association'
  autoload :BelongsToAssociation,     'active_resource/associations/belongs_to_association'
  autoload :Delegation,     'active_resource/associations/delegation'
  autoload :Relation,     'active_resource/associations/relation'
  autoload :AssociationRelation,     'active_resource/associations/association_relation'
  autoload :CollectionProxy,     'active_resource/associations/collection_proxy'

  module ClassMethods
    # Specifies a one-to-many association.
    #
    # === Options
    # [:class_name]
    #   Specify the class name of the association. This class name would
    #   be used for resolving the association class.
    #
    # ==== Example for [:class_name] - option
    # GET /posts/123.json delivers following response body:
    #   {
    #     title: "ActiveResource now has associations",
    #     body: "Lorem Ipsum"
    #     comments: [
    #       {
    #         content: "..."
    #       },
    #       {
    #         content: "..."
    #       }
    #     ]
    #   }
    # ====
    #
    # <tt>has_many :comments, :class_name => 'myblog/comment'</tt>
    # Would resolve those comments into the <tt>Myblog::Comment</tt> class.
    #
    # If the response body does not contain an attribute matching the association name
    # a request sent to the index action under the current resource.
    # For the example above, if the comments are not present the requested path would be:
    # GET /posts/123/comments.xml
    def has_many(name, options = {})
      Builder::HasMany.build(self, name, options)
    end

    # Specifies a one-to-one association.
    #
    # === Options
    # [:class_name]
    #   Specify the class name of the association. This class name would
    #   be used for resolving the association class.
    #
    # ==== Example for [:class_name] - option
    # GET /posts/1.json delivers following response body:
    #   {
    #     title: "ActiveResource now has associations",
    #     body: "Lorem Ipsum",
    #     author: {
    #       name: "Gabby Blogger",
    #     }
    #   }
    # ====
    #
    # <tt>has_one :author, :class_name => 'myblog/author'</tt>
    # Would resolve this author into the <tt>Myblog::Author</tt> class.
    #
    # If the response body does not contain an attribute matching the association name
    # a request is sent to a singelton path under the current resource.
    # For example, if a Product class <tt>has_one :inventory</tt> calling <tt>Product#inventory</tt>
    # will generate a request on /products/:product_id/inventory.json.
    #
    def has_one(name, options = {})
      Builder::HasOne.build(self, name, options)
    end

    # Specifies a one-to-one association with another class. This class should only be used
    # if this class contains the foreign key.
    #
    # Methods will be added for retrieval and query for a single associated object, for which
    # this object holds an id:
    #
    # [association(force_reload = false)]
    #   Returns the associated object. +nil+ is returned if the foreign key is +nil+.
    #   Throws a ActiveResource::ResourceNotFound exception if the foreign key is not +nil+
    #   and the resource is not found.
    #
    # (+association+ is replaced with the symbol passed as the first argument, so
    # <tt>belongs_to :post</tt> would add among others <tt>post.nil?</tt>.
    #
    # === Example
    #
    # A Comment class declaress <tt>belongs_to :post</tt>, which will add:
    # * <tt>Comment#post</tt> (similar to <tt>Post.find(post_id)</tt>)
    # The declaration can also include an options hash to specialize the behavior of the association.
    #
    # === Options
    # [:class_name]
    #   Specify the class name for the association. Use it only if that name canÄt be inferred from association name.
    #   So <tt>belongs_to :post</tt> will by default be linked to the Post class, but if the real class name is Article,
    #   you'll have to specify it with whis option.
    # [:foreign_key]
    #   Specify the foreign key used for the association. By default this is guessed to be the name
    #   of the association with an "_id" suffix. So a class that defines a <tt>belongs_to :post</tt>
    #   association will use "post_id" as the default <tt>:foreign_key</tt>. Similarly,
    #   <tt>belongs_to :article, :class_name => "Post"</tt> will use a foreign key
    #   of "article_id".
    #
    # Option examples:
    # <tt>belongs_to :customer, :class_name => 'User'</tt>
    # Creates a belongs_to association called customer which is represented through the <tt>User</tt> class.
    #
    # <tt>belongs_to :customer, :foreign_key => 'user_id'</tt>
    # Creates a belongs_to association called customer which would be resolved by the foreign_key <tt>user_id</tt> instead of <tt>customer_id</tt>
    #
    def belongs_to(name, options={})
      Builder::BelongsTo.build(self, name, options)
    end
  end
  
  # Clears out the association cache.
  def clear_association_cache #:nodoc:
    @association_cache.clear if persisted?
  end

  # :nodoc:
  attr_reader :association_cache
  
  class AssociationNotFoundError < ActiveResource::ConfigurationError
    def initialize(record, association_name)
      super("Association named '#{association_name}' was not found on #{record.class.name}; perhaps you misspelled it?")
    end
  end

  # Returns the association instance for the given name, instantiating it if it doesn't already exist
  def association(name) #:nodoc:
    association = association_instance_get(name)

    if association.nil?
      raise AssociationNotFoundError.new(self, name) unless reflection = self.class.reflect_on_association(name)
      association = reflection.association_class.new(self, reflection)
      association_instance_set(name, association)
    end

    association
  end
  
  private
    # Returns the specified association instance if it responds to :loaded?, nil otherwise.
    def association_instance_get(name)
      @association_cache[name]
    end

    # Set the specified association instance.
    def association_instance_set(name, association)
      @association_cache[name] = association
    end

end
