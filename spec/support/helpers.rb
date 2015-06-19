module Helpers
  def webmock_element(model)
    stub_request(:get, "#{model.class.site}#{model.class.element_name}/#{model.id}")
        .with(query: hash_including({current_user: 'Anonymous'}))
        .to_return(body: model.attributes.to_hash.to_json,
                   status: 200)
  end

  def webmock_collection(models)
    stub_request(:get, "#{models.sample.class.site}#{models.sample.class.collection_name}")
        .with(query: hash_including({current_user: 'Anonymous'}))
        .to_return(body: models.map(&:attributes).map { |o| Hash[o.each_pair.to_a] }.to_json,
                   status: 200)
  end

  def webmock_action(model, method, action, params = {})
    stub_request(method.to_sym, "#{model.class.site}#{model.class.element_name}/#{model.id}/#{action}")
        .with(query: hash_including({current_user: 'Anonymous'}.merge(params)))
  end

  def webmock_action_with_body(model, method, action, body, params = {})
    if method == 'get'
      stub_request(method.to_sym, "#{model.class.site}#{model.class.element_name}/#{model.id}/#{action}")
          .with(query: {current_user: 'Anonymous'})
          .to_return(body: body.to_json)
    else
      stub_request(method.to_sym, "#{model.class.site}#{model.class.element_name}/#{model.id}/#{action}")
          .with(body: body.merge({current_user: 'Anonymous'}).to_json)
    end
  end

  def webmock_activity(site, trackable, id)
    stub_request(:get, "#{site}activity")
        .with(query: {current_user: 'Anonymous', trackable: trackable, trackable_id: id})

  end
end