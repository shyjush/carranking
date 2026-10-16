# Archived legacy migrations

These 58 migrations are preserved for audit only and are intentionally excluded from Supabase deployment.

They contain the retired reputation system and externally collected review/owner-report batches. CarRanking now treats its own member ratings and owner reviews as the only review originals, and does not deploy these historical external-review migrations.

Archived on 2026-10-17 after `supabase db push` showed that these local files predated the current remote migration history. No database rows were deleted or overwritten by this archive move.
