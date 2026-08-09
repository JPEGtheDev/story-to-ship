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

---

## Qualitative Render-Capture-Look Example

Unlike a regression test, a qualitative test has no baseline and no pass/fail pixel comparison. It always exits successfully in the GTest sense -- its value is the saved image and the agent's description of that image after reading it.

```cpp
TEST_F(RenderingQualitativeTest, Qualitative_ParameterSweep_BlurRadiusComparison)
{
    // Skip if the render fixture data is not present on this machine
    const std::string data_path = "test_data/render_fixture";
    if (!std::filesystem::exists(data_path)) {
        GTEST_SKIP() << "Render fixture data not present -- qualitative test requires real data";
    }

    SceneModel model;
    model.loadFromFixture(data_path);

    // Render at multiple parameter values and save each for inspection
    for (auto [suffix, blur_radius] : std::initializer_list<std::pair<const char*, float>>{
             {"blur60", 6.0f}, {"blur20", 2.0f}, {"blur10", 1.0f}, {"blur05", 0.5f}})
    {
        // modelShader, view, projection, blurRadiusLoc set up as in the regression example
        glUniform1f(blurRadiusLoc, blur_radius);
        glContext_.bindFramebuffer();
        renderModel(model, modelShader, view, projection);

        Image img = glContext_.captureFramebuffer();
        img.save("artifacts/qualitative_" + std::string(suffix) + ".png", ImageFormat::PNG);

        // Print inline statistics -- the agent reads these alongside the image, not instead of it
        auto stats = analyzeImage(img);
        std::cout << "[" << suffix << "] coverage=" << stats.coverage_pct << "% "
                  << "rgb=(" << stats.avg_r << "," << stats.avg_g << "," << stats.avg_b << ")\n";
    }
}
```

After the test runs, the agent reads each saved artifact image and describes what it sees:

> "blur60: surface opacity is low near the edges -- artifact bleed is visible past the model silhouette. blur10: surface is fully opaque, no artifact bleed past the silhouette boundary."

That description is the diagnosis. It does not come from reading the shader. It comes from looking at the image.

- **Coverage near 0%**: the pipeline is not producing output. Stop and diagnose the render path before examining shader code.
- **Coverage looks right but the image is wrong**: the pipeline is alive but the content is incorrect. Read the image to determine what is actually wrong.

The image is always the primary artifact. Statistics are annotations on the image.
