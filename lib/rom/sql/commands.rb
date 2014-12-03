module Commands
  ERRORS = [
    Sequel::UniqueConstraintViolation,
    Sequel::NotNullConstraintViolation
  ].freeze

  Result = Struct.new(:value, :errors) {
    def on_success(&block)
      block.call(value) if value
      self
    end

    def on_errors(&block)
      block.call(errors) if errors.any?
      self
    end
  }

  class Create
    include Concord.new(:relation, :input, :validator)

    def self.build(relation, definition)
      new(relation, definition.input, definition.validator)
    end

    def execute(tuple)
      attributes = input[tuple]
      validator.call(attributes)

      pk = relation.insert(attributes.to_h)

      relation.where(relation.model.primary_key => pk)
    end
  end

  class Update
    include Concord.new(:relation, :input, :validator)

    def self.build(relation, definition)
      new(relation, definition.input, definition.validator)
    end

    def execute(tuple)
      attributes = input[tuple]
      validator.call(attributes)

      pks = relation.map { |t| t[relation.model.primary_key] }

      relation.update(attributes.to_h)
      relation.unfiltered.where(relation.model.primary_key => pks)
    end
    alias_method :set, :execute

    def new(*args, &block)
      self.class.new(relation.public_send(*args, &block), input, validator)
    end
  end

  class Delete
    include Concord.new(:relation, :target)

    def self.build(relation, target = relation)
      new(relation, target)
    end

    def execute
      target.delete
      relation
    end

    def new(*args, &block)
      self.class.new(relation, relation.public_send(*args, &block))
    end
  end

end
