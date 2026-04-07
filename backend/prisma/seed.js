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

  // ── Admin par défaut ───────────────────────────────────────────
  const adminPassword = await bcrypt.hash('Admin@FlashDoc2024!', 12);
  const admin = await prisma.user.upsert({
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
  console.log(`✅ Admin créé : ${admin.email}`);

  // ── Médecin de test ────────────────────────────────────────────
  const doctorPassword = await bcrypt.hash('Doctor@Test2024!', 12);
  const doctorUser = await prisma.user.upsert({
    where:  { phone: '+237611111111' },
    update: {},
    create: {
      phone:     '+237611111111',
      email:     'dr.test@flashdoc.cm',
      password:  doctorPassword,
      role:      'DOCTOR',
      status:    'ACTIVE',
      firstName: 'Jean',
      lastName:  'Mballa',
      doctor: {
        create: {
          speciality:   'Généraliste',
          onmcNumber:   'ONMC-CM-001234',
          status:       'APPROVED',
          isAvailable:  false,
          city:         'Douala',
          languages:    ['fr'],
          bio:          'Médecin généraliste avec 10 ans d\'expérience à Douala.',
        },
      },
    },
  });
  console.log(`✅ Médecin test créé : ${doctorUser.email}`);

  // ── Patient de test ────────────────────────────────────────────
  const patientPassword = await bcrypt.hash('Patient@Test2024!', 12);
  const patientUser = await prisma.user.upsert({
    where:  { phone: '+237622222222' },
    update: {},
    create: {
      phone:     '+237622222222',
      email:     'patient.test@flashdoc.cm',
      password:  patientPassword,
      role:      'PATIENT',
      status:    'ACTIVE',
      firstName: 'Marie',
      lastName:  'Nguemo',
      patient: {
        create: {
          gender:    'F',
          bloodType: 'O+',
          city:      'Yaoundé',
          allergies: [],
        },
      },
    },
  });
  console.log(`✅ Patient test créé : ${patientUser.email}`);

  console.log('\n🎉 Seed terminé avec succès !');
  console.log('─────────────────────────────────────────');
  console.log('Comptes de test :');
  console.log('  Admin   : +237600000000 / Admin@FlashDoc2024!');
  console.log('  Médecin : +237611111111 / Doctor@Test2024!');
  console.log('  Patient : +237622222222 / Patient@Test2024!');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); });
