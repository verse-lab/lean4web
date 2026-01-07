import { atom } from 'jotai'
import { atomWithQuery } from 'jotai-tanstack-query'

import lean4webConfig from '../config/config'
import { lookupUrl } from '../utils/UrlParsing'
import { urlArgsAtom, urlArgsStableAtom } from './url-atoms'

/** Get the URL for the default example, if configured */
function getDefaultExampleUrl(): string | undefined {
  const defaultExample = lean4webConfig.defaultExample
  if (!defaultExample) return undefined
  return `/api/example/${defaultExample.project}/${defaultExample.file}`
}

/**
 * Stores the import-URL.
 *
 * This is needed for the comparison which puts the URL back into the location hash if
 * the current code matches the one from the import-URL.
 */
export const importUrlAtom = atom<string>()

/**
 * Stores the imported code.
 *
 * This is needed for the comparison which puts the URL back into the location hash if
 * the current code matches the one from the import-URL.
 */
export const importedCodeAtom = atom<string>()

/** Query to fetch the code from the import URL or default example */
const freshlyImportedCodeQueryAtom = atomWithQuery((get) => {
  const urlArgs = get(urlArgsStableAtom)
  // Use URL from args, or fall back to default example if no code is specified
  const hasExplicitCode = urlArgs.code || urlArgs.codez
  const url = urlArgs.url ?? (hasExplicitCode ? undefined : getDefaultExampleUrl())
  return {
    queryKey: ['importedCode', url],
    queryFn: async () => {
      if (!url) return undefined
      const res = await fetch(lookupUrl(url))
      const code = res.ok ? await res.text() : `Error: failed to load code from ${url}`
      return code
    },
    enabled: url !== undefined,
    keepPreviousData: true,
  }
})

export const freshlyImportedCodeAtom = atom((get) => {
  const { data } = get(freshlyImportedCodeQueryAtom)
  return data
})

/**
 * Load code from the import URL and run it with the specified project.
 *
 * If no project is provided, the project remains unchanged.
 */
export const setImportUrlAndProjectAtom = atom(
  null,
  (get, set, val: { url: string; project?: string }) => {
    const urlArgs = get(urlArgsStableAtom)
    set(urlArgsAtom, {
      ...urlArgs,
      url: val.url,
      project: val.project ?? urlArgs.project,
      code: undefined,
      codez: undefined,
    })
  },
)
