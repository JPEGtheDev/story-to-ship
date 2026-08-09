# Visual Regression Testing -- Examples and Utilities

## Writing a Visual Regression Test

Use production classes directly -- **never duplicate production logic in test helpers**.

```cpp
TEST_F(RenderingRegressionTest, RenderDefaultCube_AngledView_MatchesBaseline)
{
    // Arrange
    Shader modelShader(vertexPath.c_str(), fragmentPath.c_str());
    SceneModel model;  // Production class directly -- no test helper duplication
    glm::mat4 view = glm::lookAt(cameraPos, cameraTarget, cameraUp);
    glm::mat4 projection = glm::perspective(glm::radians(45.0f), aspect, 0.1f, 3000.0f);

    // Act
    glContext_.bindFramebuffer();
    renderModel(model, modelShader, view, projection);
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

| Type | Role | Purpose |
|------|------|---------|
| `Image` | The project's image utility | RGBA pixel buffer with save/load (PPM, PNG) |
| `ComparisonResult` | The project's testing support library | Match status, similarity, diff image |
| `PixelComparator` | The project's testing support library | Pixel comparison engine |
| `ImageFormat` | The project's image utility | Format enum (PPM, PNG) for Image::save/load |
