defmodule Formwang.Repo.Migrations.FixMigrationStatus do
  use Ecto.Migration

  def change do
    # 手动插入迁移记录到 schema_migrations 表
    execute """
    INSERT INTO schema_migrations (version, inserted_at) VALUES
    ('20250101000001', NOW()),
    ('20250101000002', NOW()),
    ('20250101000003', NOW()),
    ('20250101000004', NOW()),
    ('20250101000005', NOW()),
    ('20250101000006', NOW())
    ON CONFLICT (version) DO NOTHING;
    """
  end
end
