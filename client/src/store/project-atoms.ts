import { atom } from 'jotai'

import lean4webConfig from '../config/config'
import { urlArgsAtom, urlArgsStableAtom } from './url-atoms'

/** Get the default project - from defaultExample config, or first project in list */
function getDefaultProject(): string {
  if (lean4webConfig.defaultExample) {
    return lean4webConfig.defaultExample.project
  }
  return lean4webConfig.projects[0]?.folder ?? 'MathlibDemo'
}

/** The currently selected project */
export const projectAtom = atom(
  (get) => {
    const urlArgs = get(urlArgsStableAtom)
    return urlArgs.project ?? getDefaultProject()
  },
  (get, set, project: string) => {
    const urlArgs = get(urlArgsStableAtom)
    const defaultProject = getDefaultProject()
    set(urlArgsAtom, { ...urlArgs, project: project !== defaultProject ? project : undefined })
  },
)
