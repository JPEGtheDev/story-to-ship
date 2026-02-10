# Testing Examples and Patterns

This reference provides concrete examples of correct and incorrect test patterns for Particle-Viewer. Load this when writing or reviewing tests.

---

## AAA Pattern — Critical Rules

1. **NEVER combine phases.** Do not write `// Arrange & Act` or `// Act & Assert`. Each phase gets its own comment and section.
2. **If no Arrange is needed**, omit `// Arrange` entirely — start with `// Act`.
3. **Move expected values to Arrange** as named variables, not inline in Assert.
4. **One logical concept per test** — split if testing multiple behaviors.

---

## AAA Pattern — Correct Examples

### Unit Test: Camera Movement

```cpp
TEST(CameraTest, MoveForward_DefaultSpeed_IncreasesPosition)
{
    // Arrange
    Camera camera(800, 600);
    camera.cameraPos = glm::vec3(0.0f, 0.0f, 0.0f);
    camera.setSpeed(1.0f);

    // Act
    camera.moveForward();

    // Assert
    EXPECT_LT(camera.cameraPos.z, 0.0f);
}
```

### Unit Test: Constructor with Named Expected Values

```cpp
TEST(ImageTest, Constructor_WithDimensions_SetsWidthAndHeight)
{
    // Arrange
    uint32_t expected_width = 16;
    uint32_t expected_height = 32;

    // Act
    Image image(expected_width, expected_height);

    // Assert
    EXPECT_EQ(image.width, expected_width);
    EXPECT_EQ(image.height, expected_height);
}
```

### Unit Test: No Arrange Needed (Omit It)

```cpp
TEST(ImageTest, DefaultConstructor_CreatesEmptyImage)
{
    // Act
    Image image;

    // Assert
    EXPECT_TRUE(image.empty());
}
```

### Visual Regression: Exact Match

```cpp
TEST_F(VisualRegressionTest, ExactMatch_IdenticalSolidImages_Passes)
{
    // Arrange
    Image baseline = createTestImage(16, 16, 255, 0, 0);
    Image current = createTestImage(16, 16, 255, 0, 0);

    // Act
    ComparisonResult result = comparator_.compare(baseline, current, 0.0f, true);

    // Assert
    EXPECT_TRUE(result.matches);
    EXPECT_TRUE(result.error.empty());
}
```

### Visual Regression: Tolerance Match

```cpp
TEST_F(VisualRegressionTest, TolerantMatch_SlightlyDifferentImages_Passes)
{
    // Arrange
    Image baseline = createTestImage(16, 16, 128, 128, 128);
    Image current = createTestImage(16, 16, 129, 127, 128);
    float tolerance = VisualTestConfig::TOLERANT_THRESHOLD;

    // Act
    ComparisonResult result = comparator_.compare(baseline, current, tolerance, false);

    // Assert
    EXPECT_TRUE(result.matches);
    EXPECT_TRUE(result.error.empty());
}
```

### Visual Regression: Using Production Particle Class

```cpp
TEST_F(RenderingRegressionTest, RenderSingleParticle_CenteredView_MatchesBaseline)
{
    // Arrange
    Shader particleShader(vertexPath.c_str(), fragmentPath.c_str());
    std::vector<glm::vec4> data = {glm::vec4(0.0f, 0.0f, 0.0f, 0.0f)};
    Particle particles(1, data.data());  // Use production Particle class
    glm::mat4 view = glm::lookAt(cameraPos, cameraTarget, cameraUp);
    glm::mat4 projection = glm::perspective(glm::radians(45.0f), aspect, 0.1f, 3000.0f);

    // Act
    glContext_.bindFramebuffer();
    renderParticle(particles, particleShader, view, projection);
    Image currentImage = glContext_.captureFramebuffer();

    // Assert
    ASSERT_TRUE(currentImage.valid());
    Image baseline = Image::load(baselinePath, ImageFormat::PNG);
    PixelComparator comparator;
    ComparisonResult result = comparator.compare(baseline, currentImage, tolerance, true);
    EXPECT_TRUE(result.matches);
}
```

### Image Save/Load: Round-Trip (RGB preserved, alpha discarded)

```cpp
TEST(VisualHelperTest, ImageLoad_PPM_RoundTrip_PreservesPixels)
{
    // Arrange
    Image original = createTestImage(4, 4, 200, 100, 50);
    std::string path = "/tmp/visual_test_roundtrip.ppm";
    original.save(path, ImageFormat::PPM);

    // Act
    Image loaded = Image::load(path, ImageFormat::PPM);

    // Assert
    EXPECT_TRUE(loaded.valid());
    EXPECT_EQ(loaded.width, original.width);
    EXPECT_EQ(loaded.height, original.height);
    EXPECT_EQ(loaded.pixels[0], 200u); // R preserved
    EXPECT_EQ(loaded.pixels[1], 100u); // G preserved
    EXPECT_EQ(loaded.pixels[2], 50u);  // B preserved
    EXPECT_EQ(loaded.pixels[3], 255u); // A set to 255 (alpha discarded in PPM)

    std::remove(path.c_str());
}
```

---

## AAA Pattern — INCORRECT Examples (Do NOT Follow)

### ❌ Combined Arrange & Act

```cpp
// BAD: "Arrange & Act" combined
TEST(ImageTest, DefaultConstructor_CreatesEmptyImage)
{
    // Arrange & Act  <-- WRONG: Don't combine
    Image image;

    // Assert
    EXPECT_TRUE(image.empty());
}
```

**Fix:** Omit `// Arrange` entirely, start with `// Act`.

### ❌ Combined Act & Assert

```cpp
// BAD: "Act & Assert" combined
TEST_F(VisualRegressionTest, ExactMatch_IdenticalImages_Passes)
{
    // Arrange
    Image baseline = createTestImage(16, 16, 255, 0, 0);
    Image current = createTestImage(16, 16, 255, 0, 0);

    // Act & Assert  <-- WRONG: Don't combine
    assertVisualMatch(baseline, current, "test_name");
}
```

**Fix:** Separate into `// Act` (run comparison) and `// Assert` (check result).

### ❌ Inline Expected Values in Assert

```cpp
// BAD: Magic numbers in assert
TEST(ImageTest, Constructor_SetsSize)
{
    // Act
    Image image(16, 32);

    // Assert
    EXPECT_EQ(image.width, 16);   // <-- WRONG: 16 is a magic number
    EXPECT_EQ(image.height, 32);  // <-- WRONG: 32 is a magic number
}
```

**Fix:** Put expected values as named variables in Arrange.

### ❌ Testing External Library Behavior

```cpp
// BAD: Testing std::vector, not our code
TEST(ImageTest, PixelVector_Resizes)
{
    // Arrange
    std::vector<uint8_t> pixels(100);

    // Act
    pixels.resize(200);

    // Assert
    EXPECT_EQ(pixels.size(), 200u);  // <-- WRONG: Testing std::vector
}
```

**Fix:** Only test YOUR code — wrapper logic, integration, or behavior you own.

### ❌ Vague Test Name

```cpp
// BAD: No clear behavior being tested
TEST(CameraTest, WorksProperly)     // <-- WRONG
TEST(ShaderTest, TestShader)        // <-- WRONG
TEST(CameraTest, Update)            // <-- WRONG
```

**Fix:** Use `UnitName_StateUnderTest_ExpectedResult` format.

### ❌ Duplicating Production Logic in Test Helpers

```cpp
// BAD: Test helper class recreates Particle's cube generation logic
class ParticleRenderer {
    void createDefaultCube() {
        // Duplicated from Particle() constructor  <-- WRONG
        for (int i = 0; i < 64000; i++) {
            particleData_[i] = glm::vec4(i % 40 * 1.25, ...);
        }
    }
};
```

**Fix:** Use `Particle` directly — tests stay in sync with production code automatically.

```cpp
// GOOD: Use production class
Particle particles;  // Default cube, same as app
// Or with custom data:
std::vector<glm::vec4> data = {glm::vec4(0.0f, 0.0f, 0.0f, 0.0f)};
Particle particles(1, data.data());
```

---

## Key Types Reference

### Particle (src/particle.hpp)

```cpp
class Particle
{
  public:
    long n;                              // number of bodies
    GLuint instanceVBO;                  // GL instance buffer
    std::vector<glm::vec4> translations; // positions (x, y, z, colorValue)
    std::vector<glm::vec4> velocities;   // velocity data

    Particle();                                        // Default: 64,000 particles in 40×40×40 grid
    Particle(long number_of_bodies, const glm::vec4* positions); // Custom data (copies)

    void changeTranslations(long count, const glm::vec4* new_positions);
    void changeVelocities(const glm::vec4* new_velocities);
    void pushVBO();            // Upload translations to GPU
    void setUpInstanceArray(); // Configure vertex attribs for instancing
};
```

### Image (src/Image.hpp)

```cpp
class Image
{
  public:
    uint32_t width;
    uint32_t height;
    std::vector<uint8_t> pixels; // RGBA, 4 bytes per pixel

    Image();                           // Default: empty
    Image(uint32_t w, uint32_t h);    // Allocates w*h*4 bytes, zeroed
    bool empty() const;
    bool valid() const;

    // Save to file (drops alpha, writes RGB)
    bool save(const std::string& path, ImageFormat format) const;

    // Load from file (sets alpha to 255)
    static Image load(const std::string& path, ImageFormat format);
};

enum class ImageFormat { PPM, PNG };
```

### ComparisonResult (src/testing/PixelComparator.hpp)

```cpp
struct ComparisonResult
{
    bool matches;
    float similarity;        // 0.0 to 1.0 (1.0 = identical)
    uint32_t diff_pixels;
    uint32_t total_pixels;
    BoundingBox diff_bounds;
    Image diff_image;        // Red overlay on differing pixels
    std::string error;       // Non-empty on error (dimension mismatch, etc.)
};
```

### PixelComparator (src/testing/PixelComparator.hpp)

```cpp
class PixelComparator
{
  public:
    PixelComparator();
    ComparisonResult compare(const Image& baseline, const Image& current,
                            float tolerance, bool generate_diff = false) const;
    void setMode(ComparisonMode mode);  // EXACT or TOLERANT
    ComparisonMode getMode() const;
};
```

### Visual Test Helpers (tests/visual-regression/VisualTestHelpers.hpp)

```cpp
// Create solid-color RGBA image
Image createTestImage(uint32_t w, uint32_t h, uint8_t r, uint8_t g, uint8_t b, uint8_t a = 255);

// Create horizontal gradient (clamped to [0,255])
Image createGradientImage(uint32_t w, uint32_t h,
                          uint8_t r1, uint8_t g1, uint8_t b1,
                          uint8_t r2, uint8_t g2, uint8_t b2);
```

---

## Test Directory Structure

```
tests/
├── core/               # Unit tests (CameraTests.cpp, ParticleTests.cpp, etc.)
├── integration/        # Multi-component tests
├── testing/            # Tests for PixelComparator, Image
├── visual-regression/  # Visual comparison tests (uses production Particle class)
│   ├── baselines/      # Baseline images (committed, never modified by tests)
│   └── RenderingRegressionTests.cpp
├── mocks/              # MockOpenGL.hpp/.cpp
├── stb_image_write_impl.cpp
└── CMakeLists.txt
```
