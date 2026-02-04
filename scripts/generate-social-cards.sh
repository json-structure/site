#!/bin/bash
# Generate social card SVG files for each blog post

SOCIAL_CARDS_DIR="social-cards"
POSTS_DIR="_posts"

# Create social-cards directory
mkdir -p "$SOCIAL_CARDS_DIR"

# Read the social card template
read_template() {
  cat << 'TEMPLATE'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="1200" height="630" viewBox="0 0 1200 630" xmlns="http://www.w3.org/2000/svg">
  <!-- Background -->
  <rect width="1200" height="630" fill="#ffffff"/>
  
  <!-- Left panel background -->
  <rect x="0" y="0" width="400" height="630" fill="#f8f9fa"/>
  
  <!-- Vertical separator line (doesn't touch top/bottom) -->
  <line x1="400" y1="80" x2="400" y2="550" stroke="#4078c0" stroke-width="3"/>
  
  <!-- JSON Structure Logo - scaled and positioned -->
  <g transform="translate(92, 120) scale(0.21)">
    <path d="M772.46 1068C788.087 1068 801.065 1068.91 811.395 1070.74 821.725 1072.57 831.26 1074.98 840 1077.97L830.465 1162.69C821.195 1161.03 812.256 1159.78 803.647 1158.95 795.04 1158.12 787.027 1157.71 779.611 1157.71 760.806 1157.71 746.437 1165.18 736.504 1180.13 726.572 1195.08 721.605 1216.18 721.605 1243.43 721.605 1272.33 724.651 1299.91 730.743 1326.16 736.835 1352.4 739.882 1379.98 739.882 1408.89 739.882 1441.78 730.743 1467.28 712.468 1485.38 694.192 1503.49 668.632 1512.88 635.789 1513.54L635.789 1530.49C668.632 1531.15 694.192 1540.87 712.468 1559.64 730.743 1578.41 739.882 1603.58 739.882 1635.15 739.882 1665.38 736.835 1693.62 730.743 1719.87 724.651 1746.11 721.605 1773.03 721.605 1800.6 721.605 1830.84 726.572 1854.18 736.504 1870.62 746.437 1887.07 760.806 1895.29 779.611 1895.29 787.027 1895.29 795.04 1894.79 803.647 1893.8 812.256 1892.8 821.195 1891.64 830.465 1890.31L840 1975.03C831.26 1978.02 821.725 1980.43 811.395 1982.26 801.065 1984.09 788.087 1985 772.46 1985 729.286 1985 695.847 1968.8 672.142 1936.41 648.436 1904.02 636.584 1858.75 636.584 1800.6 636.584 1772.69 639.365 1745.12 644.927 1717.87 650.489 1690.63 653.27 1662.39 653.27 1633.15 653.27 1614.55 646.98 1600.01 634.399 1589.54 621.817 1579.08 607.118 1571.77 590.298 1567.62 573.48 1563.46 558.713 1561.39 546 1561.39L546 1482.64C555.27 1482.64 565.931 1481.07 577.983 1477.91 590.033 1474.75 601.82 1470.1 613.342 1463.95 624.864 1457.81 634.399 1450.25 641.947 1441.28 649.496 1432.31 653.27 1422.17 653.27 1410.88 653.27 1380.31 650.489 1351.74 644.927 1325.16 639.365 1298.58 636.584 1271.33 636.584 1243.43 636.584 1187.28 648.436 1144 672.142 1113.6 695.847 1083.2 729.286 1068 772.46 1068Z" fill="#215F9A" fill-rule="evenodd" transform="translate(-398, -959)"/>
    <path d="M1231.54 1068C1274.71 1068 1308.15 1083.2 1331.86 1113.6 1355.56 1144 1367.42 1187.28 1367.42 1243.43 1367.42 1271.33 1364.63 1298.58 1359.07 1325.16 1353.51 1351.74 1350.73 1380.31 1350.73 1410.88 1350.73 1422.17 1354.5 1432.31 1362.05 1441.28 1369.6 1450.25 1379.14 1457.81 1390.66 1463.95 1402.18 1470.1 1414.03 1474.75 1426.22 1477.91 1438.4 1481.07 1448.99 1482.64 1458 1482.64L1458 1561.39C1445.29 1561.39 1430.52 1563.46 1413.7 1567.62 1396.88 1571.77 1382.18 1579.08 1369.6 1589.54 1357.02 1600.01 1350.73 1614.55 1350.73 1633.15 1350.73 1662.39 1353.51 1690.63 1359.07 1717.87 1364.63 1745.12 1367.42 1772.69 1367.42 1800.6 1367.42 1858.75 1355.56 1904.02 1331.86 1936.41 1308.15 1968.8 1274.71 1985 1231.54 1985 1216.18 1985 1203.27 1984.09 1192.8 1982.26 1182.34 1980.43 1172.74 1978.02 1164 1975.03L1173.53 1890.31C1182.81 1891.64 1191.74 1892.8 1200.35 1893.8 1208.96 1894.79 1216.97 1895.29 1224.39 1895.29 1243.19 1895.29 1257.56 1887.07 1267.5 1870.62 1277.43 1854.18 1282.39 1830.84 1282.39 1800.6 1282.39 1773.03 1279.35 1746.11 1273.26 1719.87 1267.16 1693.62 1264.12 1665.38 1264.12 1635.15 1264.12 1603.58 1273.26 1578.41 1291.53 1559.64 1309.81 1540.87 1335.37 1531.15 1368.21 1530.49L1368.21 1513.54C1335.37 1512.88 1309.81 1503.49 1291.53 1485.38 1273.26 1467.28 1264.12 1441.78 1264.12 1408.89 1264.12 1379.98 1267.16 1352.4 1273.26 1326.16 1279.35 1299.91 1282.39 1272.33 1282.39 1243.43 1282.39 1216.18 1277.43 1195.08 1267.5 1180.13 1257.56 1165.18 1243.19 1157.71 1224.39 1157.71 1216.97 1157.71 1208.96 1158.12 1200.35 1158.95 1191.74 1159.78 1182.81 1161.03 1173.53 1162.69L1164 1077.97C1172.74 1074.98 1182.34 1072.57 1192.8 1070.74 1203.27 1068.91 1216.18 1068 1231.54 1068Z" fill="#215F9A" fill-rule="evenodd" transform="translate(-398, -959)"/>
    <rect x="380" y="324" width="418" height="91.0001" fill="#4E95D9"/>
    <rect x="512" y="464" width="286" height="91.9998" fill="#4E95D9"/>
    <rect x="380" y="605" width="418" height="91.9998" fill="#4E95D9"/>
    <rect x="512" y="746" width="286" height="92.0001" fill="#4E95D9"/>
  </g>
  
  <!-- "JSON Structure" text below logo -->
  <text x="200" y="470" text-anchor="middle" font-family="system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif" font-weight="700" fill="#333333" font-size="32">JSON Structure</text>
  
  <!-- "Blog" label -->
  <text x="200" y="510" text-anchor="middle" font-family="system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif" font-weight="400" fill="#666666" font-size="20">Blog</text>
  
  <!-- Right panel: Post title with word wrapping using foreignObject -->
  <switch>
    <foreignObject x="440" y="100" width="720" height="380" requiredExtensions="http://www.w3.org/1999/xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml" style="height: 100%; display: flex; align-items: center;">
        <p style="font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; font-weight: 600; font-size: 48px; color: #333333; margin: 0; line-height: 1.3; word-wrap: break-word;">TITLE_PLACEHOLDER</p>
      </div>
    </foreignObject>
    <!-- Fallback for renderers that don't support foreignObject -->
    <text x="460" y="315" font-family="system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif" font-weight="600" fill="#333333" font-size="48">TITLE_PLACEHOLDER</text>
  </switch>
  
  <!-- Date -->
  <text x="460" y="540" font-family="system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif" font-weight="400" fill="#888888" font-size="24">DATE_PLACEHOLDER</text>
</svg>
TEMPLATE
}

# Process each post
for post_file in "$POSTS_DIR"/*.md; do
  if [ -f "$post_file" ]; then
    filename=$(basename "$post_file")
    
    # Extract slug from filename (remove date prefix and .md extension)
    # Format: YYYY-MM-DD-slug.md
    slug=$(echo "$filename" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-//' | sed 's/\.md$//')
    
    # Extract title from front matter
    title=$(grep -m1 '^title:' "$post_file" | sed 's/^title:[[:space:]]*//' | sed 's/^["'\'']//' | sed 's/["'\'']$//')
    
    # Extract date from front matter or filename
    date_raw=$(grep -m1 '^date:' "$post_file" | sed 's/^date:[[:space:]]*//')
    if [ -z "$date_raw" ]; then
      date_raw=$(echo "$filename" | grep -o '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}')
    fi
    
    # Format date nicely
    if [ -n "$date_raw" ]; then
      # Parse YYYY-MM-DD format
      year=$(echo "$date_raw" | cut -d'-' -f1)
      month=$(echo "$date_raw" | cut -d'-' -f2)
      day=$(echo "$date_raw" | cut -d'-' -f3 | cut -d' ' -f1)
      
      # Convert month number to name
      case $month in
        01) month_name="January" ;;
        02) month_name="February" ;;
        03) month_name="March" ;;
        04) month_name="April" ;;
        05) month_name="May" ;;
        06) month_name="June" ;;
        07) month_name="July" ;;
        08) month_name="August" ;;
        09) month_name="September" ;;
        10) month_name="October" ;;
        11) month_name="November" ;;
        12) month_name="December" ;;
        *) month_name="$month" ;;
      esac
      
      formatted_date="$month_name $day, $year"
    else
      formatted_date=""
    fi
    
    # Escape special characters for XML
    title_escaped=$(echo "$title" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
    
    # Generate SVG
    output_file="$SOCIAL_CARDS_DIR/${slug}.svg"
    read_template | sed "s/TITLE_PLACEHOLDER/$title_escaped/g" | sed "s/DATE_PLACEHOLDER/$formatted_date/g" > "$output_file"
    
    echo "Generated: $output_file"
  fi
done

echo "Social card generation complete!"
