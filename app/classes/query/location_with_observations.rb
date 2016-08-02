class Query::LocationWithObservations < Query::Location
  include Query::Initializers::ObservationFilters

  def parameter_declarations
    super.merge(observation_filter_parameter_declarations)
  end

  def initialize_flavor
    add_join(:observations)
    initialize_observation_filters
    super
  end
end

