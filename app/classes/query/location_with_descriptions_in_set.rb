class Query::LocationWithDescriptionsInSet < Query::LocationBase
  include Query::Initializers::InSet

  def parameter_declarations
    super.merge(
      ids:        [LocationDescription],
      old_title?: :string,
      old_by?:    :string
    )
  end

  def initialize_flavor
    initialize_in_set_flavor("location_descriptions")
    add_join(:location_descriptions)
    super
  end

  def coerce_into_location_description_query
    Query.lookup(:LocationDescription, :in_set, params)
  end
end
