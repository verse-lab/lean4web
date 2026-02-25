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
        { file: 'Examples/Tutorial/RingFin.lean', name: 'Ring (Concrete)' },
        { file: 'Examples/Tutorial/RingDec.lean', name: 'Ring (Decidable)' },
        { file: 'Examples/Tutorial/RingNat.lean', name: 'Ring (Naturals)' },
        { file: 'Examples/Synchronous/FloodSet.lean', name: 'Flood Set' },
        { file: 'Examples/Puzzles/DieHard.lean', name: 'DieHard' },
        { file: 'Examples/Ivy/TwoPhaseCommit.lean', name: 'Two Phase Commit (Ivy)' },
        { file: 'Examples/TLA/TwoPhaseCommit.lean', name: 'Two Phase Commit (TLA)' },
        { file: 'Examples/Ivy/RicartAgrawala.lean', name: 'Ricart Agrawala' },
        { file: 'Examples/Ivy/ReliableBroadcast.lean', name: 'Reliable Broadcast' },
        { file: 'Examples/Ivy/SuzukiKasami.lean', name: 'Suzuki Kasami' },
        { file: 'Examples/Ivy/PaxosEPR.lean', name: 'Paxos EPR' },
        { file: 'Examples/Ivy/NOPaxos.lean', name: 'NOPaxos' },
      ],
    },
  ],
  // Load the Ring example by default when opening the page
  defaultExample: {
    project: 'Veil',
    file: 'Examples/Tutorial/RingDec.lean',
  },
  serverCountry: null,
  contactDetails: null,
  impressum: null,
}

export default lean4webConfig
