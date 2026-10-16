# Hasobjy Figma reference fixtures

Source: file `11anMMsG6zbMHejcOukYC7`, retrieved through Figma MCP on 2026-10-16.

- `hasobjy_figma_content_rects.json`: direct Content children from page metadata for the 62 frame variants composed with PreviewScaffold. Measurements are at 390 × 844. Center wrappers are measured by their rendered child; Spacer is excluded. The eleven existing dark frames retain their earlier independent button/card assertions.
- `hasobjy_figma_text_styles.json`: 907 uniquely identifiable text slots across the 88 reference contexts. Color, size, and weight come from Figma paragraph styles (including inherited styles), never from the Flutter values. Duplicate labels and unresolved component placeholders are excluded.
- The complete frame inventory, original contexts, metadata, source screenshots, and simulator comparison artifacts are in `reports/figma-design/update-2026-10-16/`.

A failing assertion requires comparing the actual frame with its current Figma context. Do not regenerate these fixtures from Flutter output to make a regression pass. Reinspect Figma through MCP when the design changes. These checks supplement visual review; they do not prove backend behavior or exact pixel equality.
