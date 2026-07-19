# Implementation Plan: Cloudy Visibility & Mobile Layout Optimization

This plan addresses readability issues in the Cloudy weather theme and ensures the mobile navigation bar doesn't obscure content.

## Proposed Changes

### 🎨 Cloudy Visibility & Impact

#### [MODIFY] [weather_model.dart](file:///C:/Users/Kshitij/Desktop/portfolio_website/frontend/lib/models/weather_model.dart)
- **Refined Accent**: Change the `accentColor` for `WeatherCondition.clouds` from a light silver to a more visible **Slate Blue-Grey** (`0xFF546E7A`).
- **Secondary Polish**: Ensure `tertiaryTextColor` has enough contrast on light backgrounds.

#### [MODIFY] [portfolio_content.dart](file:///C:/Users/Kshitij/Desktop/portfolio_website/frontend/lib/widgets/portfolio_content.dart)
- **Cloud Aura**: Darken the cloud color in `_drawCloudEffect` to a medium grey (`0xFF90A4AE`) so it's visible against the Alabaster background.
- **Darker Hover**: In `_HoverCard`, increase the hover background opacity from `0.08` to `0.15` and deepen the shadow to create a more impactful "lifting" effect.
- **Meta-data Visibility**:
    - Update `_buildEducation`, `_buildExperience`, and `_buildProjects` to ensure years, grades, and tech tags use a higher contrast version of the accent color when in light mode.

### 📱 Mobile Layout Fix

#### [MODIFY] [home_screen.dart](file:///C:/Users/Kshitij/Desktop/portfolio_website/frontend/lib/screens/home_screen.dart)
- **Bottom Spacing**: Add a `bottomPadding` parameter to both `PortfolioContent` and `PostFeed` components.

#### [MODIFY] [portfolio_content.dart](file:///C:/Users/Kshitij/Desktop/portfolio_website/frontend/lib/widgets/portfolio_content.dart)
- **Mobile Scroll Padding**: Add a bottom padding of `100px` to the `SingleChildScrollView` when running in mobile mode to ensure content is not hidden by the floating TabBar.

#### [MODIFY] [post_feed.dart](file:///C:/Users/Kshitij/Desktop/portfolio_website/frontend/lib/widgets/post_feed.dart)
- **Mobile Scroll Padding**: Add a bottom padding of `100px` to the `ListView` when running in mobile mode.

---

## Verification Plan

### Manual Verification
1.  **Readability Check**: Cycle to the "Clouds" theme. Verify that education years, grades, and tech tags are now dark and clearly readable.
2.  **Hover Impact**: Hover over cards in both light and dark themes. Verify the hover state feels more distinct and "deeper".
3.  **Cloud Aura**: Verify the profile pic's cloud aura is visible and looks like soft grey clouds.
4.  **Mobile Scroll**: Switch to mobile view. Scroll to the bottom of both "Me" and "Snapshots" tabs. Verify that the last items are fully visible above the floating bar.
