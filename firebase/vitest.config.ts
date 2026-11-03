import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Every test shares one emulator, so test files run one at a time.
    fileParallelism: false,
    testTimeout: 15_000,
    hookTimeout: 30_000,
  },
});
