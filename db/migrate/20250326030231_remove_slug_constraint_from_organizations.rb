class RemoveSlugConstraintFromOrganizations < ActiveRecord::Migration[7.1]
  def change
    change_column_null :organizations, :slug, true
  end
end
