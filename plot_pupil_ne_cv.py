"""Build 4-panel supplemental figure for pupil vs pupil+NE CV comparison."""
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib as mpl

CSV = '/Users/sleeper/Projects/Neurodynamic-control-toolbox/glmhmm_pupil_ne_cv_results.csv'
OUT = '/Users/sleeper/Projects/Neurodynamic-control-toolbox/glmhmm_pupil_ne_cv_figure.png'

df = pd.read_csv(CSV)

mpl.rcParams.update({
    'font.family': ['Helvetica Neue', 'Helvetica', 'Arial', 'DejaVu Sans'],
    'font.size': 10,
    'axes.spines.top': False,
    'axes.spines.right': False,
    'axes.linewidth': 0.8,
    'axes.edgecolor': '#333333',
    'axes.labelcolor': '#222222',
    'xtick.color': '#333333',
    'ytick.color': '#333333',
    'xtick.major.size': 3,
    'ytick.major.size': 3,
    'xtick.major.width': 0.8,
    'ytick.major.width': 0.8,
    'axes.grid': True,
    'grid.color': '#E8E8E8',
    'grid.linewidth': 0.6,
    'grid.alpha': 1.0,
    'axes.axisbelow': True,
})

PUPIL_COLOR = '#8B7355'    # muted brown
PUPIL_NE_COLOR = '#4F6D8A'  # muted slate blue
BG = '#FAFAFA'

metrics = [
    ('accuracy',        'Accuracy',        None),
    ('roc_auc',         'ROC-AUC',         None),
    ('pr_auc',          'PR-AUC',          None),
    ('bits_per_trial',  'Bits / trial',    None),
]

fig, axes = plt.subplots(2, 2, figsize=(8, 6), facecolor=BG)
fig.subplots_adjust(left=0.1, right=0.97, top=0.93, bottom=0.1, hspace=0.42, wspace=0.3)

for ax, (metric, label, _) in zip(axes.flat, metrics):
    ax.set_facecolor(BG)
    for model, color, offset in [('Pupil', PUPIL_COLOR, -0.08),
                                  ('Pupil+NE', PUPIL_NE_COLOR, +0.08)]:
        sub = df[df['model'] == model]
        Ks = sorted(sub['K'].unique())
        means = [sub[sub['K'] == k][metric].mean() for k in Ks]
        sems = [sub[sub['K'] == k][metric].sem() for k in Ks]
        x_line = np.array(Ks) + offset
        # Scatter folds
        for k in Ks:
            vals = sub[sub['K'] == k][metric].values
            jitter = (np.random.default_rng(hash((model, k, metric)) & 0xFFFF).random(len(vals)) - 0.5) * 0.06
            ax.scatter(np.full_like(vals, k, dtype=float) + offset + jitter, vals,
                       s=14, color=color, alpha=0.35, edgecolors='none', zorder=2)
        ax.errorbar(x_line, means, yerr=sems, fmt='o-', color=color,
                    markersize=6, linewidth=1.5, capsize=0, zorder=3,
                    label=model, markeredgecolor='white', markeredgewidth=0.8)
    ax.set_xlabel('Number of states (K)')
    ax.set_ylabel(label)
    ax.set_xticks([1, 2, 3, 4])
    ax.set_xlim(0.6, 4.4)

# Legend in top-left only
axes[0, 0].legend(frameon=False, loc='lower right', fontsize=9)

fig.suptitle('Pupil vs. pupil+NE as state-transition drivers (49-session matched subset, 5-fold CV)',
             fontsize=11, color='#222222', y=0.985)

plt.savefig(OUT, dpi=300, facecolor=BG, bbox_inches='tight')
print(f"Saved: {OUT}")
