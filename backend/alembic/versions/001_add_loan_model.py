"""Add loan model and enhance schema

Revision ID: 001
Revises: 
Create Date: 2024-01-05 15:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = '001'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    # Create loans table
    op.create_table('loans',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('borrower_name', sa.String(length=255), nullable=False),
        sa.Column('loan_amount', sa.Float(), nullable=False),
        sa.Column('status', sa.String(length=50), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('owner_id', sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(['owner_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('idx_loan_owner_status', 'loans', ['owner_id', 'status'])
    op.create_index(op.f('ix_loans_borrower_name'), 'loans', ['borrower_name'])
    op.create_index(op.f('ix_loans_id'), 'loans', ['id'])

    # Enhance users table
    op.add_column('users', sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('NOW()')))
    op.alter_column('users', 'email', type_=sa.String(length=255), nullable=False)
    op.alter_column('users', 'hashed_password', type_=sa.String(length=255), nullable=False)
    op.alter_column('users', 'role', type_=sa.String(length=50), nullable=False)
    op.alter_column('users', 'is_active', nullable=False)

    # Enhance covenants table
    op.add_column('covenants', sa.Column('loan_id', sa.Integer(), nullable=False))
    op.add_column('covenants', sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('NOW()')))
    op.alter_column('covenants', 'name', type_=sa.String(length=255), nullable=False)
    op.alter_column('covenants', 'threshold', nullable=False)
    op.alter_column('covenants', 'operator', type_=sa.String(length=10), nullable=False)
    op.alter_column('covenants', 'category', type_=sa.String(length=50), nullable=False)
    op.alter_column('covenants', 'status', type_=sa.String(length=50), nullable=False)
    op.create_foreign_key('fk_covenant_loan', 'covenants', 'loans', ['loan_id'], ['id'])
    op.create_index('idx_covenant_loan_status', 'covenants', ['loan_id', 'status'])

    # Enhance audit_logs table
    op.add_column('audit_logs', sa.Column('loan_id', sa.Integer(), nullable=True))
    op.alter_column('audit_logs', 'timestamp', nullable=False)
    op.alter_column('audit_logs', 'event_type', type_=sa.String(length=100), nullable=False)
    op.alter_column('audit_logs', 'details', type_=sa.Text(), nullable=False)
    op.create_foreign_key('fk_audit_loan', 'audit_logs', 'loans', ['loan_id'], ['id'])
    op.create_index(op.f('ix_audit_logs_event_type'), 'audit_logs', ['event_type'])
    op.create_index(op.f('ix_audit_logs_timestamp'), 'audit_logs', ['timestamp'])

def downgrade():
    # Remove indexes and constraints
    op.drop_index('idx_covenant_loan_status', table_name='covenants')
    op.drop_constraint('fk_covenant_loan', 'covenants', type_='foreignkey')
    op.drop_constraint('fk_audit_loan', 'audit_logs', type_='foreignkey')
    op.drop_index('idx_loan_owner_status', table_name='loans')
    op.drop_index(op.f('ix_loans_borrower_name'), table_name='loans')
    op.drop_index(op.f('ix_loans_id'), table_name='loans')
    op.drop_index(op.f('ix_audit_logs_event_type'), table_name='audit_logs')
    op.drop_index(op.f('ix_audit_logs_timestamp'), table_name='audit_logs')

    # Remove columns
    op.drop_column('users', 'created_at')
    op.drop_column('covenants', 'loan_id')
    op.drop_column('covenants', 'created_at')
    op.drop_column('audit_logs', 'loan_id')

    # Drop loans table
    op.drop_table('loans')
