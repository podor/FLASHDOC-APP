const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Démarrage du seed FlashDoc...');

  // ── Spécialités médicales ──────────────────────────────────────
  const specialities = [
    { name: 'Généraliste',        description: 'Médecine générale' },
    { name: 'Cardiologue',        description: 'Maladies du cœur et des vaisseaux' },
    { name: 'Dermatologue',       description: 'Maladies de la peau' },
    { name: 'Pédiatre',           description: 'Médecine de l\'enfant' },
    { name: 'Gynécologue',        description: 'Santé de la femme' },
    { name: 'Ophtalmologue',      description: 'Maladies des yeux' },
    { name: 'ORL',                description: 'Oreille, nez, gorge' },
    { name: 'Neurologue',         description: 'Maladies du système nerveux' },
    { name: 'Psychiatre',         description: 'Santé mentale' },
    { name: 'Urologue',           description: 'Maladies de l\'appareil urinaire' },
    { name: 'Gastro-entérologue', description: 'Maladies digestives' },
    { name: 'Orthopédiste',       description: 'Maladies des os et articulations' },
  ];

  for (const spec of specialities) {
    await prisma.speciality.upsert({
      where:  { name: spec.name },
      update: {},
      create: spec,
    });
  }
  console.log(`✅ ${specialities.length} spécialités créées`);

  // ── Admin ──────────────────────────────────────────────────────
  const adminPassword = await bcrypt.hash('Admin@FlashDoc2024!', 12);
  await prisma.user.upsert({
    where:  { phone: '+237600000000' },
    update: {},
    create: {
      phone:     '+237600000000',
      email:     'admin@flashdoc.cm',
      password:  adminPassword,
      role:      'ADMIN',
      status:    'ACTIVE',
      firstName: 'Admin',
      lastName:  'FlashDoc',
    },
  });
  console.log('✅ Admin : +237600000000 / Admin@FlashDoc2024!');

  // ── Médecin 1 — Généraliste ────────────────────────────────────
  const doctorPassword = await bcrypt.hash('Doctor@Test2024!', 12);
  await prisma.user.upsert({
    where:  { phone: '+237611111111' },
    update: {},
    create: {
      phone:     '+237611111111',
      email:     'dr.mballa@flashdoc.cm',
      password:  doctorPassword,
      role:      'DOCTOR',
      status:    'ACTIVE',
      firstName: 'Jean',
      lastName:  'Mballa',
      doctor: {
        create: {
          speciality:    'Généraliste',
          onmcNumber:    'ONMC-CM-001234',
          status:        'APPROVED',
          isAvailable:   false,
          city:          'Douala',
          languages:     ['fr'],
          bio:           'Médecin généraliste avec 10 ans d\'expérience à Douala.',
          averageRating: 8.2,
          totalConsults: 247,
        },
      },
    },
  });
  console.log('✅ Médecin 1 : +237611111111 / Doctor@Test2024! (Généraliste)');

  // ── Médecin 2 — Cardiologue ────────────────────────────────────
  const doctor2Password = await bcrypt.hash('Doctor@Test2024!', 12);
  await prisma.user.upsert({
    where:  { phone: '+237611111112' },
    update: {},
    create: {
      phone:     '+237611111112',
      email:     'dr.mbarga@flashdoc.cm',
      password:  doctor2Password,
      role:      'DOCTOR',
      status:    'ACTIVE',
      firstName: 'Paul',
      lastName:  'Mbarga',
      doctor: {
        create: {
          speciality:    'Cardiologue',
          onmcNumber:    'ONMC-CM-005678',
          status:        'APPROVED',
          isAvailable:   false,
          city:          'Yaoundé',
          languages:     ['fr', 'en'],
          bio:           'Cardiologue spécialisé en maladies cardiovasculaires.',
          averageRating: 9.1,
          totalConsults: 183,
        },
      },
    },
  });
  console.log('✅ Médecin 2 : +237611111112 / Doctor@Test2024! (Cardiologue)');

  // ── Médecin 3 — Pédiatre ──────────────────────────────────────
  const doctor3Password = await bcrypt.hash('Doctor@Test2024!', 12);
  await prisma.user.upsert({
    where:  { phone: '+237611111113' },
    update: {},
    create: {
      phone:     '+237611111113',
      email:     'dr.ngo@flashdoc.cm',
      password:  doctor3Password,
      role:      'DOCTOR',
      status:    'ACTIVE',
      firstName: 'Sylvie',
      lastName:  'Ngo Biyong',
      doctor: {
        create: {
          speciality:    'Pédiatre',
          onmcNumber:    'ONMC-CM-009012',
          status:        'APPROVED',
          isAvailable:   false,
          city:          'Douala',
          languages:     ['fr'],
          bio:           'Pédiatre dédiée à la santé des enfants de 0 à 18 ans.',
          averageRating: 7.8,
          totalConsults: 312,
        },
      },
    },
  });
  console.log('✅ Médecin 3 : +237611111113 / Doctor@Test2024! (Pédiatre)');

  // ── Patient 1 — Marie Nguemo ───────────────────────────────────
  const patientPassword = await bcrypt.hash('Patient@Test2024!', 12);
  await prisma.user.upsert({
    where:  { phone: '+237622222222' },
    update: {},
    create: {
      phone:     '+237622222222',
      email:     'marie.nguemo@gmail.com',
      password:  patientPassword,
      role:      'PATIENT',
      status:    'ACTIVE',
      firstName: 'Marie',
      lastName:  'Nguemo',
      patient: {
        create: {
          gender:    'FEMALE',
          bloodType: 'AB+',
          birthDate: new Date('2002-03-15'), // 24 ans
          city:      'Douala',
          allergies: ['Pénicilline'],
        },
      },
    },
  });
  console.log('✅ Patient 1 : +237622222222 / Patient@Test2024! (Marie Nguemo)');

  // ── Patient 2 — Paul Nkomo ─────────────────────────────────────
  const patient2Password = await bcrypt.hash('Patient@Test2024!', 12);
  await prisma.user.upsert({
    where:  { phone: '+237633333333' },
    update: {},
    create: {
      phone:     '+237633333333',
      email:     'paul.nkomo@gmail.com',
      password:  patient2Password,
      role:      'PATIENT',
      status:    'ACTIVE',
      firstName: 'Paul',
      lastName:  'Nkomo',
      patient: {
        create: {
          gender:    'MALE',
          bloodType: 'O+',
          birthDate: new Date('1988-07-22'), // 37 ans
          city:      'Yaoundé',
          allergies: [],
        },
      },
    },
  });
  console.log('✅ Patient 2 : +237633333333 / Patient@Test2024! (Paul Nkomo)');

  console.log('\n🎉 Seed terminé avec succès !');
  console.log('═══════════════════════════════════════════════');
  console.log('  COMPTES DE DÉMO FlashDoc');
  console.log('═══════════════════════════════════════════════');
  console.log('  👑 Admin    : +237600000000 / Admin@FlashDoc2024!');
  console.log('  🩺 Médecin 1: +237611111111 / Doctor@Test2024!');
  console.log('  🩺 Médecin 2: +237611111112 / Doctor@Test2024!');
  console.log('  🩺 Médecin 3: +237611111113 / Doctor@Test2024!');
  console.log('  👤 Patient 1: +237622222222 / Patient@Test2024!');
  console.log('  👤 Patient 2: +237633333333 / Patient@Test2024!');
  console.log('═══════════════════════════════════════════════');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); });
