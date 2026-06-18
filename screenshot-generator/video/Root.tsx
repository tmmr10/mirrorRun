import { Composition } from "remotion";
import {
  MirrorRunnersPreview,
  FPS,
  DURATION_FRAMES,
  WIDTH,
  HEIGHT,
} from "./MirrorRunnersPreview";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="MirrorRunnersPreview"
        component={MirrorRunnersPreview}
        durationInFrames={DURATION_FRAMES}
        fps={FPS}
        width={WIDTH}
        height={HEIGHT}
        defaultProps={{ locale: "en" as const }}
      />
      <Composition
        id="MirrorRunnersPreviewDE"
        component={MirrorRunnersPreview}
        durationInFrames={DURATION_FRAMES}
        fps={FPS}
        width={WIDTH}
        height={HEIGHT}
        defaultProps={{ locale: "de" as const }}
      />
    </>
  );
};
