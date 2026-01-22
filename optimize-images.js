#!/usr/bin/env node

import sharp from 'sharp';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const INPUT_DIR = path.join(__dirname, 'input-images');
const OUTPUT_DIR = path.join(__dirname, 'public', 'images');

// Ensure output directory exists
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

// Image mapping with specifications
const imageMap = {
  '604826096': { target: 'hero-r10-landscape.jpg', width: 1920, quality: 85 },
  '508823578': { target: 'services-demolition.jpg', width: 1200, quality: 85 },
  '539002334': { target: 'product-r15-closeup.jpg', width: 1200, quality: 85 },
  '582763021': { target: 'product-r10-showroom.jpg', width: 1200, quality: 85 },
  '592715356': { target: 'inventory-tractors.jpg', width: 1200, quality: 85 },
  '604379632': { target: 'detail-comfort-seat.jpg', width: 800, quality: 80 },
  '604538472': { target: 'detail-blue-paint.jpg', width: 800, quality: 80 },
  '480802071': { target: 'logo-brand.jpg', width: 400, quality: 85 },
};

const processImage = async (inputPath, outputPath, width, quality) => {
  try {
    const inputSize = fs.statSync(inputPath).size;

    await sharp(inputPath)
      .resize(width, null, { withoutEnlargement: true })
      .jpeg({ quality })
      .toFile(outputPath);

    const outputSize = fs.statSync(outputPath).size;
    const reduction = ((1 - outputSize / inputSize) * 100).toFixed(1);

    return {
      status: 'success',
      inputSize: Math.round(inputSize / 1024),
      outputSize: Math.round(outputSize / 1024),
      reduction: reduction
    };
  } catch (err) {
    return { status: 'error', error: err.message };
  }
};

const processRemainingImages = async (processed) => {
  const files = fs.readdirSync(INPUT_DIR).filter(f => f.endsWith('.jpg'));
  const results = [];

  for (const file of files) {
    const match = file.match(/^(\d+)_/);
    if (!match || processed.has(match[1])) continue;

    const inputPath = path.join(INPUT_DIR, file);
    const outputName = `equipment-${Date.now()}-${Math.random().toString(36).substr(2, 9)}.jpg`;
    const outputPath = path.join(OUTPUT_DIR, outputName);

    console.log(`Processing remaining: ${file}...`);
    const result = await processImage(inputPath, outputPath, 1200, 85);

    if (result.status === 'success') {
      console.log(`  ✓ ${Math.round(result.inputSize)}KB → ${Math.round(result.outputSize)}KB (${result.reduction}% reduction)`);
    } else {
      console.log(`  ✗ Error: ${result.error}`);
    }

    results.push({
      original: file,
      output: outputName,
      ...result
    });
  }

  return results;
};

(async () => {
  console.log('Starting image optimization...\n');
  const processedIds = new Set();
  const results = [];

  // Process mapped images
  for (const [id, spec] of Object.entries(imageMap)) {
    processedIds.add(id);
    const files = fs.readdirSync(INPUT_DIR).filter(f => f.startsWith(id));

    if (files.length === 0) {
      console.log(`⚠ No image found for ID ${id}`);
      continue;
    }

    const inputPath = path.join(INPUT_DIR, files[0]);
    const outputPath = path.join(OUTPUT_DIR, spec.target);

    console.log(`Processing ${spec.target}...`);
    const result = await processImage(inputPath, outputPath, spec.width, spec.quality);

    if (result.status === 'success') {
      console.log(`  ✓ ${result.inputSize}KB → ${result.outputSize}KB (${result.reduction}% reduction)\n`);
    } else {
      console.log(`  ✗ Error: ${result.error}\n`);
    }

    results.push({
      original: files[0],
      output: spec.target,
      ...result
    });
  }

  // Process remaining images
  console.log('Processing remaining unassigned images...\n');
  const remainingResults = await processRemainingImages(processedIds);
  results.push(...remainingResults);

  // Summary
  console.log('\n=== SUMMARY ===');
  const totalInput = results.reduce((sum, r) => sum + (r.inputSize || 0), 0);
  const totalOutput = results.reduce((sum, r) => sum + (r.outputSize || 0), 0);
  console.log(`Total input: ${totalInput}KB`);
  console.log(`Total output: ${totalOutput}KB`);
  console.log(`Overall reduction: ${((1 - totalOutput / totalInput) * 100).toFixed(1)}%`);

  // List output files
  console.log('\n=== OUTPUT FILES ===');
  const outputFiles = fs.readdirSync(OUTPUT_DIR);
  outputFiles.forEach(f => {
    const size = fs.statSync(path.join(OUTPUT_DIR, f)).size;
    console.log(`${f}: ${Math.round(size / 1024)}KB`);
  });
})();
