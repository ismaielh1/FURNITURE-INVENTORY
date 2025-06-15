import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { target_email, new_password } = await req.json();
    if (!target_email || !new_password || new_password.length < 6) {
      throw new Error("Invalid input provided.");
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // 1. استدعاء دالة SQL الجديدة للحصول على ID المستخدم الصحيح
    const { data: userId, error: rpcError } = await supabaseAdmin.rpc('get_user_id_by_email', {
      target_email: target_email
    });

    if (rpcError) throw rpcError;
    if (!userId) {
      throw new Error(`User with email ${target_email} not found.`);
    }

    console.log(`Found user with ID: ${userId}`);

    // 2. تحديث كلمة المرور باستخدام الـ ID الصحيح الذي حصلنا عليه
    const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
      userId,
      { password: new_password }
    );

    if (updateError) throw updateError;

    console.log(`Successfully initiated password update for user: ${userId}`);

    return new Response(JSON.stringify({ message: 'Password update initiated successfully' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    console.error('Caught an error in the function:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
