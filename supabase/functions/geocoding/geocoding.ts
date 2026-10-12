export type City = {
  name: string;
  region?: string;
  country?: string;
  countryCode?: string;
};
export type Place = {
  label: string;
  latitude: number;
  longitude: number;
  city: City | null;
};
const text = (value: unknown): string | undefined =>
  typeof value === "string" && value.trim()
    ? value.trim().slice(0, 120)
    : undefined;
export function normalizePlace(value: Record<string, unknown>): Place | null {
  const latitude = Number(value.lat), longitude = Number(value.lon);
  if (
    !Number.isFinite(latitude) || !Number.isFinite(longitude) ||
    latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180 ||
    typeof value.display_name !== "string"
  ) return null;
  const address = (value.address ?? {}) as Record<string, unknown>;
  const name = text(address.city) ?? text(address.town) ??
    text(address.village) ?? text(address.municipality);
  const city: City | null = name
    ? {
      name,
      ...(text(address.state) ? { region: text(address.state) } : {}),
      ...(text(address.country) ? { country: text(address.country) } : {}),
      ...(text(address.country_code)
        ? { countryCode: text(address.country_code) }
        : {}),
    }
    : null;
  return { label: value.display_name.slice(0, 180), latitude, longitude, city };
}
