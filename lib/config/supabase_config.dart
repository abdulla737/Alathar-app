/// Supabase project for Alathar.
///
/// The publishable key is safe to ship inside the app: it can only read
/// content, because every table has Row Level Security with read-only access.
/// NEVER put the secret key (sb_secret_…) or the database password here.
class SupabaseConfig {
  static const url = 'https://cpcqslbailuwiescesea.supabase.co';
  static const publishableKey = 'sb_publishable_WWrA8G8FCtTnKbj6vMcRDQ_MdKUurr_';
}
