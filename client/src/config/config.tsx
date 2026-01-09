import { LeanWebConfig } from './docs' // look here for documentation of the individual config options

const lean4webConfig: LeanWebConfig = {
  projects: [
    // {
    //   folder: 'MathlibDemo',
    //   name: 'Latest Mathlib',
    //   examples: [
    //     { file: 'MathlibDemo/Bijection.lean', name: 'Bijection' },
    //     { file: 'MathlibDemo/Logic.lean', name: 'Logic' },
    //     { file: 'MathlibDemo/Ring.lean', name: 'Ring' },
    //     { file: 'MathlibDemo/Rational.lean', name: 'Rational' },
    //   ],
    // },
    // { folder: 'Stable', name: 'Stable Lean' },
    {
      folder: 'Veil',
      name: 'Veil',
      examples: [
        { file: 'Examples/Tutorial/RingFin.lean', name: 'Ring Concrete' },
        { file: 'Examples/Ivy/Ring.lean', name: 'Ring' },
        { file: 'Examples/TLA/DieHard.lean', name: 'DieHard' },
        { file: 'Examples/Ivy/TwoPhaseCommit.lean', name: 'Two Phase Commit' },
        { file: 'Examples/Ivy/RicartAgrawala.lean', name: 'Ricart Agrawala' },
        { file: 'Examples/ReliableBroadcast.lean', name: 'Reliable Broadcast' },
        { file: 'Examples/SuzukiKasami.lean', name: 'Suzuki Kasami' },
        { file: 'Examples/Ivy/PaxosEPR.lean', name: 'Paxos EPR' },
        { file: 'Examples/NOPaxos.lean', name: 'NOPaxos' },
      ],
    },
  ],
  // Load the Ring example by default when opening the page
  defaultExample: {
    project: 'Veil',
    file: 'Examples/Ivy/Ring.lean',
  },
  serverCountry: null,
  contactDetails: null,
  impressum: null,
}

export default lean4webConfig
