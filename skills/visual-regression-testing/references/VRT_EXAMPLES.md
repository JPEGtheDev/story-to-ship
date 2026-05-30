# Visual Regression Testing — Examples and Utilities

## Writing a Visual Regression Test

Use production classes directly — **never duplicate production logic in test helpers**.

```cpp
TEST_F(RenderingRegressionTest, RenderDefaultCube_AngledView_MatchesBaseline)
{
    // Arrange
    Shader particleShader(vertexPath.c_str(), fragmentPath.c_str());
    Particle particles;  // Production class directly — no test helper duplication
    glm::mat4 view = glm::lookAt(cameraPos, cameraTarget, cameraUp);
    glm::mat4 projection = glm::perspective(glm::radians(45.0f), aspect, 0.1f, 3000.0f);

    // Act
    glContext_.bindFramebuffer();
    renderParticle(particles, particleShader, view, projection);
    Image currentImage = glContext_.captureFramebuffer();

    // Assert
    Image baseline = Image::load(baselinePath, ImageFormat::PNG);
    PixelComparator comparator;
    ComparisonResult result = comparator.compare(baseline, currentImage, tolerance, true);
    EXPECT_TRUE(result.matches);
}
```

---

## Testing Utilities

| Type | Location | Purpose |
|------|----------|---------|
| `Image` | `src/Image.hpp` | RGBA pixel buffer with save/load (PPM, PNG) |
| `ComparisonResult` | `src/testing/PixelComparator.hpp` | Match status, similarity, diff image |
| `PixelComparator` | `src/testing/PixelComparator.hpp` | Pixel comparison engine |
| `ImageFormat` | `src/Image.hpp` | Format enum (PPM, PNG) for Image::save/load |
| `Particle` | `src/particle.hpp` | Production particle data (std::vector<glm::vec4>) |
