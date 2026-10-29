import { Icon } from "@editor/ui/Icon";
import "@editor/components/shared/BrandMark.css";

interface BrandMarkProps {
  /** Height of the mark (CSS length). */
  height?: string;
  className?: string;
}

/**
 * The GreyStore PDF mark, rendered inline (not as an <img>) so BrandMark.css can
 * recolour it: brand green and lime at rest, the primary text colour when an
 * ancestor marked `[data-brandmark-morph]` is hovered / focused / open
 * (`.is-open`), signalling that it opens a menu.
 */
export function BrandMark({ height = "1.6rem", className }: BrandMarkProps) {
  return (
    <Icon
      name="stirling-mark"
      size={height}
      className={`sui-brandmark${className ? ` ${className}` : ""}`}
      title="GreyStore PDF"
    />
  );
}
