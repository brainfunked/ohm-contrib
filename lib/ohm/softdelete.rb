module Ohm
  # Provides support for soft deletion
  #
  # @example
  #
  #   class Post < Ohm::Model
  #     plugin :softdelete
  #
  #     attribute :title
  #     index :title
  #   end
  #
  #   post = Post.create(:title => 'Title')
  #
  #   post.deleted?
  #   # => false
  #
  #   post.delete
  #
  #   post.deleted?
  #   # => true
  #
  #   Post.all.empty?
  #   # => true
  #
  #   Post.find(:title => 'Title').include?(post)
  #   # => true
  #
  #   Post.exists?(post.id)
  #   # => true
  #
  #   post = Post[post.id]
  #
  #   post.deleted?
  #   # => true
  module SoftDelete
    DELETED_FLAG = "1"

    def self.included(model)
      model.attribute :deleted

      model.extend ClassMethods
    end

    def delete
      db.multi do |mdb|
        mdb.srem(id, model.all.key)
        mdb.sadd(id, model.deleted.key)
        set :deleted, DELETED_FLAG, mdb
      end
    end

    def restore
      db.multi do |mdb|
        mdb.sadd(id, model.all.key)
        mdb.srem(id, model.deleted.key)
        set :deleted, nil, mdb
      end
    end

    def deleted?
      deleted == DELETED_FLAG
    end

    module ClassMethods
      def deleted
        Set.new(key[:deleted], key, self)
      end

      def exists?(id)
        super || key[:deleted].sismember(id)
      end
    end
  end
end
