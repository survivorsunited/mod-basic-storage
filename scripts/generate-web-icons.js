#!/usr/bin/env node

/**
 * Generate Web Icons from Minecraft Mod Icon
 * Converts the mod icon to various sizes needed for web/documentation site
 * Uses sharp for image processing (pure JavaScript, no external dependencies)
 */

const fs = require('fs').promises;
const path = require('path');
const { existsSync } = require('fs');

// Icon sizes configuration
const iconConfigs = [
  { size: 16, name: 'favicon-16x16.png', purpose: 'Browser tab icon (small)' },
  { size: 32, name: 'favicon-32x32.png', purpose: 'Browser tab icon (standard)' },
  { size: 48, name: 'favicon-48x48.png', purpose: 'Browser tab icon (high DPI)' },
  { size: 64, name: 'favicon-64x64.png', purpose: 'Browser tab icon (very high DPI)' },
  { size: 180, name: 'apple-touch-icon.png', purpose: 'iOS home screen icon' },
  { size: 192, name: 'android-chrome-192x192.png', purpose: 'Android home screen icon' },
  { size: 512, name: 'android-chrome-512x512.png', purpose: 'Android splash screen' },
  { size: 1200, name: 'og-image.png', purpose: 'Open Graph social media preview' }
];

// Parse command line arguments
const args = process.argv.slice(2);
const force = args.includes('--force') || args.includes('-f');
const helpRequested = args.includes('--help') || args.includes('-h');

// Default paths
const sourceIcon = path.resolve('src/main/resources/assets/icon.png');
const outputDir = path.resolve('docs/static/img');

// Help message
if (helpRequested) {
  console.log(`
Generate Web Icons from Minecraft Mod Icon

Usage: node scripts/generate-web-icons.js [options]

Options:
  -f, --force    Overwrite existing icons
  -h, --help     Show this help message

Requires:
  npm install sharp png-to-ico

Source: ${sourceIcon}
Output: ${outputDir}
`);
  process.exit(0);
}

async function checkDependencies() {
  try {
    require.resolve('sharp');
    require.resolve('png-to-ico');
    return true;
  } catch (e) {
    console.error('❌ Missing required dependencies!');
    console.log('\nPlease install dependencies by running:');
    console.log('  cd scripts && npm init -y && npm install sharp png-to-ico');
    console.log('\nOr from project root:');
    console.log('  npm install --prefix scripts sharp png-to-ico');
    return false;
  }
}

async function generateIcons() {
  // Check dependencies
  if (!await checkDependencies()) {
    process.exit(1);
  }

  // Load dependencies after check
  const sharp = require('sharp');
  const pngToIco = require('png-to-ico');

  // Check if source icon exists
  if (!existsSync(sourceIcon)) {
    console.error(`❌ Source icon not found: ${sourceIcon}`);
    console.log('Please ensure the mod icon exists at the specified path.');
    process.exit(1);
  }

  // Create output directory if it doesn't exist
  if (!existsSync(outputDir)) {
    await fs.mkdir(outputDir, { recursive: true });
    console.log(`📁 Created output directory: ${outputDir}`);
  }

  console.log(`🎨 Generating web icons from: ${sourceIcon}`);

  // Generate each icon size
  for (const config of iconConfigs) {
    const outputPath = path.join(outputDir, config.name);

    // Check if file exists and force flag not set
    if (existsSync(outputPath) && !force) {
      console.log(`⏭️  Skipping ${config.name} - already exists (use --force to overwrite)`);
      continue;
    }

    console.log(`📐 Creating ${config.name} (${config.size}x${config.size}) - ${config.purpose}`);

    try {
      await sharp(sourceIcon)
        .resize(config.size, config.size, {
          fit: 'contain',
          background: { r: 0, g: 0, b: 0, alpha: 0 }
        })
        .png()
        .toFile(outputPath);

      console.log(`✅ Created ${config.name}`);
    } catch (error) {
      console.error(`❌ Failed to create ${config.name}: ${error.message}`);
    }
  }

  // Copy original icon
  const mainIconPath = path.join(outputDir, 'icon.png');
  if (existsSync(mainIconPath) && !force) {
    console.log('⏭️  Skipping icon.png - already exists (use --force to overwrite)');
  } else {
    try {
      await fs.copyFile(sourceIcon, mainIconPath);
      console.log('✅ Copied original icon.png');
    } catch (error) {
      console.error(`❌ Failed to copy icon.png: ${error.message}`);
    }
  }

  // Generate favicon.ico
  const icoPath = path.join(outputDir, 'favicon.ico');
  if (existsSync(icoPath) && !force) {
    console.log('⏭️  Skipping favicon.ico - already exists (use --force to overwrite)');
  } else {
    console.log('🔧 Creating favicon.ico (multi-resolution)');
    
    try {
      // Create multiple sizes for ICO
      const icoSizes = [16, 24, 32, 48, 64, 128, 256];
      const buffers = await Promise.all(
        icoSizes.map(size =>
          sharp(sourceIcon)
            .resize(size, size, {
              fit: 'contain',
              background: { r: 0, g: 0, b: 0, alpha: 0 }
            })
            .png()
            .toBuffer()
        )
      );

      const ico = await pngToIco(buffers);
      await fs.writeFile(icoPath, ico);
      console.log('✅ Created favicon.ico');
    } catch (error) {
      console.error(`❌ Failed to create favicon.ico: ${error.message}`);
    }
  }

  // Generate site.webmanifest
  const manifestPath = path.join(path.dirname(outputDir), 'site.webmanifest');
  const manifest = {
    name: 'Compostables Mod Documentation',
    short_name: 'Compostables',
    icons: [
      {
        src: '/img/android-chrome-192x192.png',
        sizes: '192x192',
        type: 'image/png'
      },
      {
        src: '/img/android-chrome-512x512.png',
        sizes: '512x512',
        type: 'image/png'
      }
    ],
    theme_color: '#4a7c59',
    background_color: '#ffffff',
    display: 'standalone'
  };

  try {
    await fs.writeFile(manifestPath, JSON.stringify(manifest, null, 2));
    console.log('✅ Created site.webmanifest');
  } catch (error) {
    console.error(`❌ Failed to create site.webmanifest: ${error.message}`);
  }

  console.log('\n✅ Icon generation completed successfully!');
  console.log(`Generated web icons in: ${outputDir}`);
  console.log(`Generated manifest in: ${path.dirname(outputDir)}`);
}

// Run the script
generateIcons().catch(error => {
  console.error('❌ Unexpected error:', error);
  process.exit(1);
});