/** A supported UI language code (PRD §11). */
export type Language = 'en' | 'bn';

/** A value in both product languages. */
export interface Text {
  readonly en: string;
  readonly bn: string;
}
