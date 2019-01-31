-- Create indexes for active records
CREATE INDEX activity_active_idx ON activity(active) WHERE active='t';
--CREATE INDEX boundary_active_idx ON boundary(active) WHERE active='t';
CREATE INDEX contact_active_idx ON contact(active) WHERE active='t';
CREATE INDEX detail_active_idx ON detail(active) WHERE active='t';
CREATE INDEX financial_active_idx ON financial(active) WHERE active='t';
CREATE INDEX location_active_idx ON location(active) WHERE active='t';
CREATE INDEX organization_active_idx ON organization(active) WHERE active='t';
CREATE INDEX project_active_idx ON project(active) WHERE active='t';
CREATE INDEX result_active_idx ON result(active) WHERE active='t';
CREATE INDEX taxonomy_active_idx ON taxonomy(active) WHERE active='t';
CREATE INDEX classification_active_idx ON classification(active) WHERE active='t';

-- Create index for project records
CREATE INDEX participation_activity_id_cond_idx ON participation(activity_id) WHERE activity_id IS NULL;

-- Create implied foreign key indexes 
CREATE INDEX activity_project_id_idx on activity(project_id);
CREATE INDEX contact_organization_id_idx on contact(organization_id);
CREATE INDEX detail_project_id_idx on detail(project_id);
CREATE INDEX detail_activity_id_idx on detail(activity_id);
CREATE INDEX financial_project_id_idx on financial(project_id);
CREATE INDEX financial_activity_id_idx on financial(activity_id);
CREATE INDEX location_project_id_idx on location(project_id);
CREATE INDEX location_activity_id_idx on location(activity_id);
CREATE INDEX participation_project_id_idx on participation(project_id);
CREATE INDEX participation_activity_id_idx on participation(activity_id);
CREATE INDEX result_activity_id_idx on result(activity_id);
CREATE INDEX classification_taxonomy_id_idx on classification(taxonomy_id);
CREATE INDEX activity_taxonomy_classification_id_idx on activity_taxonomy(classification_id);
--CREATE INDEX boundary_taxonomy_classification_id_idx on boundary_taxonomy(classification_id);
CREATE INDEX contact_taxonomy_classification_id_idx on contact_taxonomy(classification_id);
CREATE INDEX feature_taxonomy_classification_id_idx on feature_taxonomy(classification_id);
CREATE INDEX financial_taxonomy_classification_id_idx on financial_taxonomy(classification_id);
CREATE INDEX organization_taxonomy_classification_id_idx on organization_taxonomy(classification_id);
CREATE INDEX participation_taxonomy_classification_id_idx on participation_taxonomy(classification_id);
CREATE INDEX project_taxonomy_classification_id_idx on project_taxonomy(classification_id);
CREATE INDEX result_taxonomy_classification_id_idx on result_taxonomy(classification_id);


CREATE INDEX activity_taxonomy_activity_id_idx on activity_taxonomy(activity_id);
CREATE INDEX contact_taxonomy_contact_id_idx on contact_taxonomy(contact_id);
CREATE INDEX feature_taxonomy_feature_id_idx on feature_taxonomy(feature_id);
CREATE INDEX financial_taxonomy_financial_id_idx on financial_taxonomy(financial_id);
CREATE INDEX location_taxonomy_location_id_idx on location_taxonomy(location_id);
CREATE INDEX location_taxonomy_classification_id_idx on location_taxonomy(classification_id);
CREATE INDEX organization_taxonomy_organization_id_idx on organization_taxonomy(organization_id);
CREATE INDEX participation_taxonomy_participation_id_idx on participation_taxonomy(participation_id);
CREATE INDEX project_taxonomy_project_id_idx on project_taxonomy(project_id);
CREATE INDEX result_taxonomy_result_id_idx on result_taxonomy(result_id);

-- Create index for taxonomy_lookup
CREATE INDEX taxonomy_lookup_project_id_idx on taxonomy_lookup(project_id);
CREATE INDEX taxonomy_lookup_activity_id_idx on taxonomy_lookup(activity_id);
CREATE INDEX taxonomy_lookup_location_id_idx on taxonomy_lookup(location_id);
CREATE INDEX taxonomy_lookup_organization_id_idx on taxonomy_lookup(organization_id);
CREATE INDEX taxonomy_lookup_participation_id_idx on taxonomy_lookup(participation_id);
CREATE INDEX taxonomy_lookup_start_date_idx on taxonomy_lookup(start_date);
CREATE INDEX taxonomy_lookup_end_date_idx on taxonomy_lookup(end_date);
CREATE INDEX taxonomy_lookup_classification_id_idx on taxonomy_lookup(classification_id);
CREATE INDEX taxonomy_lookup_taxonomy_id_idx on taxonomy_lookup(taxonomy_id);

-- Create index for organization_lookup
CREATE INDEX organization_lookup_project_id_idx on organization_lookup(project_id);
CREATE INDEX organization_lookup_activity_id_idx on organization_lookup(activity_id);
CREATE INDEX organization_lookup_location_id_idx on organization_lookup(organization_id);
CREATE INDEX organization_lookup_start_date_idx on organization_lookup(start_date);
CREATE INDEX organization_lookup_end_date_idx on organization_lookup(end_date);

-- Create index for location_lookup
CREATE INDEX location_lookup_project_id_idx on location_lookup(project_id);
CREATE INDEX location_lookup_activity_id_idx on location_lookup(activity_id);
CREATE INDEX location_lookup_location_id_idx on location_lookup(location_id);
CREATE INDEX location_lookup_start_date_idx on location_lookup(start_date);
CREATE INDEX location_lookup_end_date_idx on location_lookup(end_date);
CREATE INDEX location_lookup_gaul0_name_idx on location_lookup(gaul0_name);
CREATE INDEX location_lookup_gaul1_name_idx on location_lookup(gaul1_name);
CREATE INDEX location_lookup_gaul2_name_idx on location_lookup(gaul2_name);
